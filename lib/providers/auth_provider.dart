import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Authentication status states
enum AuthStatus { initial, authenticated, unauthenticated }

/// AuthProvider manages authentication state throughout the app
class AuthProvider with ChangeNotifier {
  final AuthService _authService;
  final UserService _userService;

  // Public value notifier for widgets that only need to know if user is authenticated
  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  // Private state variables
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  bool _loading = true;
  String? _error;

  // Temporary variables for signup flow
  String? _verificationEmail;
  String? _verificationPassword;

  /// Creates a new AuthProvider with required services
  AuthProvider(this._authService, this._userService) {
    // Auto-check if user is logged in on startup
    _checkAuthStatus();
  }

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get verificationEmail => _verificationEmail;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Initialize the authentication state
  Future<void> init() async {
    await _checkAuthStatus();
  }

  /// Sign up a new user (step 1)
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
      await _authService.beginSignup(
        email,
        password,
        firstName: firstName,
        lastName: lastName,
        foodPreferences: foodPreferences,
      );

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
      String? password =
          _verificationPassword ?? await _authService.getStoredPassword();

      if (password == null) {
        throw Exception('Missing password for verification code request');
      }

      await _authService.beginSignup(email, password);
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
      await _authService.completeSignup(code);

      // Get stored email/password or use the ones we saved
      final email =
          _verificationEmail ?? await _authService.getStoredEmail() ?? '';
      final password =
          _verificationPassword ?? await _authService.getStoredPassword() ?? '';

      if (email.isEmpty || password.isEmpty) {
        throw Exception('Missing authentication data');
      }

      await _authService.signin(email, password);

      final user = await _getUserProfileOrCreateMinimal(email);
      _authenticate(user);

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
      await _authService.signin(email, password);

      final user = await _userService.getUserProfile();
      _authenticate(user);

      return true;
    } catch (e) {
      await _authService.logout();
      _setUnauthenticated();
      _setError('Login failed: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Log out the current user
  Future<void> logout() async {
    _setLoading(true);
    await _authService.logout();

    _setUnauthenticated();
    _setLoading(false);
  }

  /// Refresh the user profile data
  Future<void> refreshUserProfile() async {
    if (_status != AuthStatus.authenticated) return;

    _setLoading(true);

    try {
      final user = await _userService.getUserProfile();
      _user = user;

      notifyListeners();
    } catch (e) {
      _setError('Failed to refresh profile: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Private helper methods

  /// Check if a user is already logged in
  Future<void> _checkAuthStatus() async {
    _setLoading(true);

    try {
      final token = await _authService.getToken();

      if (token != null) {
        try {
          final user = await _userService.getUserProfile();
          _authenticate(user);
        } catch (e) {
          await _authService.logout();
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

  /// Attempt to get user profile or create a minimal user object if that fails
  Future<User> _getUserProfileOrCreateMinimal(String email) async {
    try {
      return await _userService.getUserProfile();
    } catch (e) {
      // If profile fetch fails, create minimal user
      return User(
        id: 0,
        email: email,
        firstName: '',
        lastName: '',
        isStudent: true,
        isActive: true,
        isStaff: false,
      );
    }
  }

  /// Sign in an existing user
  Future<bool> resetPassword(String email) async {
    _setLoading(true);

    try {
      await _authService.resetPassword(email);
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

  void _authenticate(User user) {
    _status = AuthStatus.authenticated;
    _user = user;
    authState.value = true;
    notifyListeners();
  }

  void _setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    _user = null;
    authState.value = false;
    notifyListeners();
  }
}
