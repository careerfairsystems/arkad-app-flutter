import 'package:arkad/view_models/profile_model.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

const String _tokenKey = 'auth_token';
const String _emailKey = 'temp_email';
const String _passwordKey = 'temp_password';

/// Authentication status states
enum AuthStatus { initial, authenticated, unauthenticated }

/// AuthProvider manages authentication state throughout the app
class AuthModel with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ArkadApi _apiService = GetIt.I<ArkadApi>();
  String token = "";

  // Public value notifier for widgets that only need to know if user is authenticated
  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  // Private state variables
  AuthStatus _status = AuthStatus.initial;
  ProfileSchema? _user;
  bool _loading = true;
  String? _error;

  // Temporary variables for signup flow
  String? _verificationEmail;
  String? _verificationPassword;

  /// Creates a new AuthProvider with required services
  AuthModel() {
    // Auto-check if user is logged in on startup
    _checkAuthStatus();
  }

  // Getters
  AuthStatus get status => _status;
  ProfileSchema? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get verificationEmail => _verificationEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize the authentication state
  Future<void> init() async {
    await _checkAuthStatus();
  }

  /// Sign up a new user (step 1)
  Future<bool> initialSignUp(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Begin signup process
      final SignupSchema signupSchema = SignupSchema((b) {
        b.email = email;
        b.password = password;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiBeginSignup(signupSchema: signupSchema);

      if (res.statusCode == 401) {
        _setError('Invalid credentials or user already exists');
        return false;
      }

      if (res.statusCode != 200) {
        _setError(
          'Failed to initiate signup: ${res.statusMessage ?? 'Unknown error'}',
        );
        return false;
      }

      // Store for later verification
      _verificationEmail = email;
      _verificationPassword = password;

      return true;
    } catch (e) {
      _setError('Sign up failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Request a new verification code
  Future<bool> requestNewVerificationCode(String email) async {
    _setLoading(true);
    _clearError();

    try {
      String? password = _verificationPassword ?? await getStoredPassword();

      if (password == null || password.isEmpty) {
        _setError(
          'Missing password for verification code request. Please try signing up again.',
        );
        return false;
      }

      final SignupSchema signupSchema = SignupSchema((b) {
        b.email = email;
        b.password = password;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiBeginSignup(signupSchema: signupSchema);

      if (res.statusCode == 401) {
        _setError('Invalid credentials. Please try signing up again.');
        return false;
      }

      if (res.statusCode != 200) {
        _setError(
          'Failed to send verification code: ${res.statusMessage ?? 'Unknown error'}',
        );
        return false;
      }

      return true;
    } catch (e) {
      _setError('Failed to request verification code: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Complete signup with verification code
  Future<bool> completeSignup(String code) async {
    _setLoading(true);
    _clearError();

    try {
      // Complete the signup process with verification code
      // Get stored email/password or use the ones we saved
      final email = _verificationEmail ?? await getStoredEmail();
      final password = _verificationPassword ?? await getStoredPassword();

      if (email == null ||
          email.isEmpty ||
          password == null ||
          password.isEmpty) {
        _setError('Missing authentication data. Please try signing up again.');
        return false;
      }

      final CompleteSignupSchema completeSignupSchema = CompleteSignupSchema((
        b,
      ) {
        b.code = code;
        b.email = email;
        b.password = password;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiCompleteSignup(
            completeSignupSchema: completeSignupSchema,
          );

      if (res.statusCode == 401) {
        _setError('Invalid verification code or expired session');
        return false;
      }

      if (res.statusCode != 200) {
        _setError(
          'Failed to complete signup: ${res.statusMessage ?? 'Unknown error'}',
        );
        return false;
      }

      _authenticate();

      // Initialize profile state with the new user
      final profileProvider = GetIt.I<ProfileModel>();
      await profileProvider.initialize();

      _verificationEmail = null;
      _verificationPassword = null;

      return true;
    } catch (e) {
      _setError('Verification failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in an existing user
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final res = await _apiService.getAuthenticationApi().userModelsApiSignin(
        signinSchema: SigninSchema((b) {
          b.email = email;
          b.password = password;
        }),
      );

      // Check for authentication errors
      if (res.statusCode == 401) {
        _setError('Invalid email or password. Please check your credentials.');
        return false;
      }

      if (res.statusCode != 200 || res.data == null) {
        _setError('Login failed: ${res.statusMessage ?? 'Unknown error'}');
        return false;
      }

      final userToken = res.data!;
      await _storage.write(key: _tokenKey, value: userToken);
      token = userToken;
      _apiService.setBearerAuth("Authorization", userToken);

      _authenticate();

      // Initialize profile state with the user
      final profileProvider = GetIt.I<ProfileModel>();
      await profileProvider.initialize();

      return true;
    } catch (e) {
      await logout();
      _setUnauthenticated();
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods

  /// Check if a user is already logged in
  Future<void> _checkAuthStatus() async {
    _setLoading(true);

    try {
      // Load token from secure storage
      final storedToken = await _storage.read(key: _tokenKey);

      if (storedToken != null && storedToken.isNotEmpty) {
        token = storedToken;
        _apiService.setBearerAuth("Authorization", storedToken);

        try {
          _authenticate();

          // Initialize profile provider with authenticated user
          final profileProvider = GetIt.I<ProfileModel>();
          await profileProvider.initialize();
        } catch (e) {
          // If authentication verification fails, logout and go to unauthenticated state
          await logout();
          _setUnauthenticated();
        }
      } else {
        _setUnauthenticated();
      }
    } catch (e) {
      _setUnauthenticated();
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in an existing user
  ///
  Future<bool> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _apiService.getAuthenticationApi().userModelsApiResetPassword(
        resetPasswordSchema: ResetPasswordSchema((b) {
          b.email = email;
        }),
      );
      return true;
    } catch (e) {
      _setError('Reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // State management helpers
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? errorMessage) {
    _error = errorMessage;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void _authenticate() {
    _status = AuthStatus.authenticated;
    authState.value = true;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _user = null;
    authState.value = false;
    notifyListeners();
  }

  Future<void> logout() async {
    _setLoading(true);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);

    _setUnauthenticated();
    _setLoading(false);
  }

  /// Retrieves stored email.
  Future<String?> getStoredEmail() async => _storage.read(key: _emailKey);

  /// Retrieves stored password.
  Future<String?> getStoredPassword() async => _storage.read(key: _passwordKey);

  Future<void> refreshUserProfile() async {
    final profileProvider = GetIt.I<ProfileModel>();
    await profileProvider.initialize();
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
