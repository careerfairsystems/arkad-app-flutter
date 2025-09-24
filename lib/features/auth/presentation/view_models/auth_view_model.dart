import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';
import '../../domain/use_cases/get_current_session_use_case.dart';
import '../../domain/use_cases/refresh_session_use_case.dart';
import '../../domain/use_cases/resend_verification_use_case.dart';
import '../../domain/use_cases/reset_password_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';
import '../commands/complete_signup_command.dart';
import '../commands/resend_verification_command.dart';
import '../commands/reset_password_command.dart';
import '../commands/sign_in_command.dart';
import '../commands/sign_up_command.dart';

/// Main authentication view model
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required CompleteSignupUseCase completeSignupUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required ResendVerificationUseCase resendVerificationUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentSessionUseCase getCurrentSessionUseCase,
    required RefreshSessionUseCase refreshSessionUseCase,
  }) : _signOutUseCase = signOutUseCase,
       _getCurrentSessionUseCase = getCurrentSessionUseCase,
       _refreshSessionUseCase = refreshSessionUseCase {
    // Initialize commands
    _signInCommand = SignInCommand(signInUseCase);
    _signUpCommand = SignUpCommand(signUpUseCase);
    _completeSignupCommand = CompleteSignupCommand(completeSignupUseCase);
    _resetPasswordCommand = ResetPasswordCommand(resetPasswordUseCase);
    _resendVerificationCommand = ResendVerificationCommand(
      resendVerificationUseCase,
    );

    // Listen to command changes
    _signInCommand.addListener(_onSignInCommandChanged);
    _signUpCommand.addListener(_onSignUpCommandChanged);
    _completeSignupCommand.addListener(_onCompleteSignupCommandChanged);
    _resetPasswordCommand.addListener(_onResetPasswordCommandChanged);
    _resendVerificationCommand.addListener(_onResendVerificationCommandChanged);

    // Initialize authentication state
    _initializeAuth();
  }

  final SignOutUseCase _signOutUseCase;
  final GetCurrentSessionUseCase _getCurrentSessionUseCase;
  final RefreshSessionUseCase _refreshSessionUseCase;

  late final SignInCommand _signInCommand;
  late final SignUpCommand _signUpCommand;
  late final CompleteSignupCommand _completeSignupCommand;
  late final ResetPasswordCommand _resetPasswordCommand;
  late final ResendVerificationCommand _resendVerificationCommand;

  // State
  AuthSession? _currentSession;
  bool _isInitializing = true;
  AppError? _globalError;
  
  // Initialization completer for Future-based waiting
  final Completer<void> _initCompleter = Completer<void>();

  // Signup flow state
  SignupData? _pendingSignupData;
  String? _signupToken;

  // Getters
  AuthSession? get currentSession => _currentSession;
  User? get currentUser => _currentSession?.user;
  bool get isAuthenticated => _currentSession?.isActive ?? false;
  bool get isInitializing => _isInitializing;
  AppError? get globalError => _globalError;
  
  /// Future that completes when authentication initialization is finished
  /// This allows other components to wait for auth state without polling
  Future<void> get waitForInitialization => _initCompleter.future;

  // Signup flow getters
  SignupData? get pendingSignupData => _pendingSignupData;
  String? get signupToken => _signupToken;
  bool get hasPendingSignup =>
      _pendingSignupData != null && _signupToken != null;

  // Command getters
  SignInCommand get signInCommand => _signInCommand;
  SignUpCommand get signUpCommand => _signUpCommand;
  CompleteSignupCommand get completeSignupCommand => _completeSignupCommand;
  ResetPasswordCommand get resetPasswordCommand => _resetPasswordCommand;
  ResendVerificationCommand get resendVerificationCommand =>
      _resendVerificationCommand;

  // Loading state getters
  bool get isSigningIn => _signInCommand.isExecuting;
  bool get isSigningUp => _signUpCommand.isExecuting;
  bool get isCompletingSignup => _completeSignupCommand.isExecuting;
  bool get isResettingPassword => _resetPasswordCommand.isExecuting;
  bool get isResendingVerification => _resendVerificationCommand.isExecuting;
  bool get isBusy =>
      isSigningIn ||
      isSigningUp ||
      isCompletingSignup ||
      isResettingPassword ||
      isResendingVerification ||
      _isInitializing;

  /// Initialize authentication state on app start
  Future<void> _initializeAuth() async {
    _isInitializing = true;
    notifyListeners();

    try {
      final result = await _getCurrentSessionUseCase.call();
      result.when(
        success: (session) {
          _currentSession = session;
          _globalError = null;
        },
        failure: (error) {
          _currentSession = null;
          // Don't set global error for missing session - this is normal
        },
      );
    } catch (e) {
      await Sentry.captureException(e);
      _currentSession = null;
    }

    _isInitializing = false;
    
    // Complete the initialization future to notify waiting components
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
    
    notifyListeners();
  }

  /// Start sign up process
  Future<void> startSignUp(SignupData signupData) async {
    _clearGlobalError();
    _pendingSignupData = signupData;
    _signupToken = null; // Clear stale token from previous attempt
    _signUpCommand.reset(); // Clear stale command state
    _completeSignupCommand.reset(); // Ensure verification command is clean

    await _signUpCommand.signUp(signupData);
  }

  /// Complete sign up process with verification code
  Future<void> completeSignUp(String verificationCode) async {
    if (_pendingSignupData == null || _signupToken == null) {
      _setGlobalError(const ValidationError("No pending signup found"));
      return;
    }

    _clearGlobalError();

    await _completeSignupCommand.completeSignup(
      signupToken: _signupToken!,
      verificationCode: verificationCode,
      signupData: _pendingSignupData!,
    );
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _clearGlobalError();
    await _signInCommand.signIn(email, password);
  }

  /// Sign out current user
  Future<void> signOut() async {
    _clearGlobalError();

    try {
      final result = await _signOutUseCase.call();
      result.when(
        success: (_) {
          _currentSession = null;
          _clearSignupState();

          _fireAuthEvent(const UserLoggedOutEvent());

          notifyListeners();
        },
        failure: (error) {
          _setGlobalError(error);
        },
      );
    } catch (e) {
      await Sentry.captureException(e);
      _setGlobalError(UnknownError(e.toString()));
    }
  }

  /// Reset password for given email
  Future<void> resetPassword(String email) async {
    _clearGlobalError();
    await _resetPasswordCommand.resetPassword(email);
  }

  /// Resend verification code for given email
  Future<void> resendVerification(String email) async {
    _clearGlobalError();
    await _resendVerificationCommand.resendVerification(email);
  }

  /// Clear signup state
  void clearSignupState() {
    _clearSignupState();
    _signUpCommand.reset();
    _completeSignupCommand.reset();
    notifyListeners();
  }

  /// Clear global error
  void clearGlobalError() {
    _clearGlobalError();
    notifyListeners();
  }

  /// Refresh current session to get updated user profile data
  Future<void> refreshSession() async {
    if (_currentSession == null) return;

    try {
      final result = await _refreshSessionUseCase.call();
      result.when(
        success: (session) {
          _currentSession = session;
          _fireAuthEvent(AuthSessionChangedEvent(session));
          notifyListeners();
        },
        failure: (error) {
          // Don't set global error for refresh failures - this is a background operation
          if (kDebugMode) {
            print('Failed to refresh session: ${error.userMessage}');
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Exception during session refresh: $e');
      }
    }
  }

  // Command listeners
  void _onSignInCommandChanged() {
    if (_signInCommand.isCompleted && _signInCommand.result != null) {
      _currentSession = _signInCommand.result;
      _clearSignupState();

      _fireAuthEvent(AuthSessionChangedEvent(_signInCommand.result!));
    }
    notifyListeners();
  }

  void _onSignUpCommandChanged() {
    if (_signUpCommand.isCompleted && _signUpCommand.result != null) {
      _signupToken = _signUpCommand.result;
    }
    notifyListeners();
  }

  void _onCompleteSignupCommandChanged() {
    if (_completeSignupCommand.isCompleted &&
        _completeSignupCommand.result != null) {
      _currentSession = _completeSignupCommand.result;
      _clearSignupState();

      _fireAuthEvent(AuthSessionChangedEvent(_completeSignupCommand.result!));
    }
    notifyListeners();
  }

  void _onResetPasswordCommandChanged() {
    notifyListeners();
  }

  void _onResendVerificationCommandChanged() {
    if (_resendVerificationCommand.isCompleted &&
        _resendVerificationCommand.result != null) {
      _signupToken = _resendVerificationCommand.result;
    }
    notifyListeners();
  }

  // Helper methods
  void _clearSignupState() {
    _pendingSignupData = null;
    _signupToken = null;
  }

  void _setGlobalError(AppError error) {
    _globalError = error;
    notifyListeners();
  }

  void _clearGlobalError() {
    _globalError = null;
  }

  void _fireAuthEvent(Object event) {
    AppEvents.fire(event);
  }

  @override
  void dispose() {
    _signInCommand.removeListener(_onSignInCommandChanged);
    _signUpCommand.removeListener(_onSignUpCommandChanged);
    _completeSignupCommand.removeListener(_onCompleteSignupCommandChanged);
    _resetPasswordCommand.removeListener(_onResetPasswordCommandChanged);
    _resendVerificationCommand.removeListener(
      _onResendVerificationCommandChanged,
    );

    _signInCommand.dispose();
    _signUpCommand.dispose();
    _completeSignupCommand.dispose();
    _resetPasswordCommand.dispose();
    _resendVerificationCommand.dispose();

    super.dispose();
  }
}
