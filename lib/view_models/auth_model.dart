import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../api/extensions.dart';
import '../shared/errors/app_error.dart';
import '../shared/errors/error_mapper.dart';

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
  AppError? _error;

  // Temporary variables for signup flow
  String? _verificationEmail;
  String? _verificationPassword;
  String? _verificationToken;
  String? _pendingFirstName;
  String? _pendingLastName;  
  String? _pendingFoodPreferences;

  /// Creates a new AuthProvider with required services
  AuthModel() {
    // Auto-check if user is logged in on startup
    _checkAuthStatus();
  }

  // Getters
  AuthStatus get status => _status;
  ProfileSchema? get user => _user;
  bool get isLoading => _loading;
  AppError? get error => _error;
  String? get verificationEmail => _verificationEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize the authentication state
  Future<void> init() async {
    await _checkAuthStatus();
  }

  /// Begin signup process with email, password, and profile data
  Future<bool> initialSignUp(
    String email, 
    String password, {
    String? firstName,
    String? lastName,
    String? foodPreferences,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Begin signup process
      final SignupSchema signupSchema = SignupSchema((b) {
        b.email = email;
        b.password = password;
        b.firstName = firstName;
        b.lastName = lastName;
        b.foodPreferences = foodPreferences;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiBeginSignup(signupSchema: signupSchema);

      if (res.isSuccess && res.data != null) {
        // Store for later verification and completion
        _verificationEmail = email;
        _verificationPassword = password;
        _verificationToken = res.data!; // The token returned by begin-signup
        _pendingFirstName = firstName;
        _pendingLastName = lastName;
        _pendingFoodPreferences = foodPreferences;
        return true;
      } else {
        _setError(ValidationError(res.error));
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        _setError(ErrorMapper.fromDioException(e, null, operationContext: 'signup'));
      } else {
        _setError(UnknownError(e.toString()));
      }
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
        _setError(ValidationError(
          'Missing password for verification code request. Please try signing up again.',
        ));
        return false;
      }

      final SignupSchema signupSchema = SignupSchema((b) {
        b.email = email;
        b.password = password;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiBeginSignup(signupSchema: signupSchema);

      if (res.isSuccess) {
        return true;
      } else {
        _setError(ValidationError(res.error));
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        _setError(ErrorMapper.fromDioException(e, null, operationContext: 'verification'));
      } else {
        _setError(UnknownError(e.toString()));
      }
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
          password.isEmpty ||
          _verificationToken == null ||
          _verificationToken!.isEmpty) {
        _setError(ValidationError('Missing authentication data or token. Please try signing up again.'));
        return false;
      }

      final CompleteSignupSchema completeSignupSchema = CompleteSignupSchema((
        b,
      ) {
        b.token = _verificationToken ?? ''; // Use the token from begin-signup
        b.code = code;
        b.email = email;
        b.password = password;
        b.firstName = _pendingFirstName;
        b.lastName = _pendingLastName;
        b.foodPreferences = _pendingFoodPreferences;
      });
      final res = await _apiService
          .getAuthenticationApi()
          .userModelsApiCompleteSignup(
            completeSignupSchema: completeSignupSchema,
          );

      if (res.isSuccess && res.data != null) {
        // Complete signup returns ProfileSchema directly
        // We need to get a token by signing in after successful signup
        final email = _verificationEmail!;
        final password = _verificationPassword!;
        
        // Clear verification and profile data
        _verificationEmail = null;
        _verificationPassword = null;
        _verificationToken = null;
        _pendingFirstName = null;
        _pendingLastName = null;
        _pendingFoodPreferences = null;
        
        // Now sign in to get the token
        return await signIn(email, password);
      } else {
        _setError(ValidationError(res.error));
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        _setError(ErrorMapper.fromDioException(e, null, operationContext: 'complete_signup'));
      } else {
        _setError(UnknownError(e.toString()));
      }
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

      if (res.isSuccess && res.data != null) {
        final userToken = res.data!;
        // Remove "Bearer " prefix if present, as the BearerAuthInterceptor will add it
        final cleanToken = userToken.startsWith('Bearer ') 
            ? userToken.substring(7) 
            : userToken;
        await _storage.write(key: _tokenKey, value: cleanToken);
        token = cleanToken;
        _apiService.setBearerAuth("AuthBearer", cleanToken);

        // Load user profile after successful authentication
        await _loadUserProfile();
        
        return true;
      } else {
        _setError(SignInError(details: res.error));
        return false;
      }
    } catch (e) {
      await logout();
      _setUnauthenticated();
      if (e is DioException) {
        _setError(ErrorMapper.fromDioException(e, null, operationContext: 'signin'));
      } else {
        _setError(UnknownError(e.toString()));
      }
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
        // Ensure the stored token doesn't have "Bearer " prefix
        final cleanToken = storedToken.startsWith('Bearer ') 
            ? storedToken.substring(7) 
            : storedToken;
        token = cleanToken;
        _apiService.setBearerAuth("AuthBearer", cleanToken);

        try {
          // Validate token by loading user profile
          await _loadUserProfile();
        } catch (e) {
          // If token validation fails, logout and go to unauthenticated state
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

  /// Reset user password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getAuthenticationApi().userModelsApiResetPassword(
        resetPasswordSchema: ResetPasswordSchema((b) {
          b.email = email;
        }),
      );
      
      if (response.isSuccess) {
        return true;
      } else {
        _setError(ValidationError(response.error));
        return false;
      }
    } catch (e) {
      if (e is DioException) {
        _setError(ErrorMapper.fromDioException(e, null, operationContext: 'password_reset'));
      } else {
        _setError(UnknownError(e.toString()));
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // State management helpers
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(AppError? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Load user profile and set authenticated state
  Future<void> _loadUserProfile() async {
    try {
      final response = await _apiService.getUserProfileApi().userModelsApiGetUserProfile();
      
      if (response.isSuccess && response.data != null) {
        _user = response.data!;
        _status = AuthStatus.authenticated;
        authState.value = true;
        notifyListeners();
      } else {
        throw Exception('Failed to load user profile: ${response.error}');
      }
    } catch (e) {
      // Clear the token if we get a 401 to force re-authentication
      if (e is DioException && e.response?.statusCode == 401) {
        await logout();
      }
      throw Exception('Profile loading failed: $e');
    }
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

  /// Refresh user profile data
  Future<void> refreshUserProfile() async {
    if (_status == AuthStatus.authenticated) {
      try {
        await _loadUserProfile();
      } catch (e) {
        if (e is DioException) {
          _setError(ErrorMapper.fromDioException(e, null, operationContext: 'profile_refresh'));
        } else {
          _setError(ProfileLoadingError(details: e.toString()));
        }
      }
    }
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
