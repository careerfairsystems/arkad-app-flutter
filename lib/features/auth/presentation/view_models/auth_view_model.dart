import 'package:flutter/foundation.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/errors/app_error.dart';
import '../../../profile/presentation/view_models/profile_view_model.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';
import '../../domain/use_cases/get_current_session_use_case.dart';
import '../../domain/use_cases/reset_password_use_case.dart';
import '../../domain/use_cases/sign_in_use_case.dart';
import '../../domain/use_cases/sign_out_use_case.dart';
import '../../domain/use_cases/sign_up_use_case.dart';
import '../commands/complete_signup_command.dart';
import '../commands/sign_in_command.dart';
import '../commands/sign_up_command.dart';

/// Main authentication view model
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required CompleteSignupUseCase completeSignupUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
    required SignOutUseCase signOutUseCase,
    required GetCurrentSessionUseCase getCurrentSessionUseCase,
  }) : _resetPasswordUseCase = resetPasswordUseCase,
       _signOutUseCase = signOutUseCase,
       _getCurrentSessionUseCase = getCurrentSessionUseCase {
    // Initialize commands
    _signInCommand = SignInCommand(signInUseCase);
    _signUpCommand = SignUpCommand(signUpUseCase);
    _completeSignupCommand = CompleteSignupCommand(completeSignupUseCase);

    // Listen to command changes
    _signInCommand.addListener(_onSignInCommandChanged);
    _signUpCommand.addListener(_onSignUpCommandChanged);
    _completeSignupCommand.addListener(_onCompleteSignupCommandChanged);

    // Initialize authentication state
    _initializeAuth();
  }

  final ResetPasswordUseCase _resetPasswordUseCase;
  final SignOutUseCase _signOutUseCase;
  final GetCurrentSessionUseCase _getCurrentSessionUseCase;

  late final SignInCommand _signInCommand;
  late final SignUpCommand _signUpCommand;
  late final CompleteSignupCommand _completeSignupCommand;

  // State
  AuthSession? _currentSession;
  bool _isInitializing = true;
  AppError? _globalError;

  // Signup flow state
  SignupData? _pendingSignupData;
  String? _signupToken;

  // Getters
  AuthSession? get currentSession => _currentSession;
  User? get currentUser => _currentSession?.user;
  bool get isAuthenticated => _currentSession?.isActive ?? false;
  bool get isInitializing => _isInitializing;
  AppError? get globalError => _globalError;

  // Signup flow getters
  SignupData? get pendingSignupData => _pendingSignupData;
  String? get signupToken => _signupToken;
  bool get hassPendingSignup => _pendingSignupData != null && _signupToken != null;

  // Command getters
  SignInCommand get signInCommand => _signInCommand;
  SignUpCommand get signUpCommand => _signUpCommand;
  CompleteSignupCommand get completeSignupCommand => _completeSignupCommand;

  // Loading state getters
  bool get isSigningIn => _signInCommand.isExecuting;
  bool get isSigningUp => _signUpCommand.isExecuting;
  bool get isCompletingSignup => _completeSignupCommand.isExecuting;
  bool get isBusy => isSigningIn || isSigningUp || isCompletingSignup || _isInitializing;

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
      _currentSession = null;
    }

    _isInitializing = false;
    notifyListeners();
  }

  /// Start sign up process
  Future<void> startSignUp(SignupData signupData) async {
    _clearGlobalError();
    _pendingSignupData = signupData;
    
    await _signUpCommand.execute(signupData);
  }

  /// Complete sign up process with verification code
  Future<void> completeSignUp(String verificationCode) async {
    if (_pendingSignupData == null || _signupToken == null) {
      _setGlobalError(const ValidationError("No pending signup found"));
      return;
    }

    _clearGlobalError();
    
    await _completeSignupCommand.execute(
      signupToken: _signupToken!,
      verificationCode: verificationCode,
      signupData: _pendingSignupData!,
    );
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    _clearGlobalError();
    await _signInCommand.execute(email, password);
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
          notifyListeners();
        },
        failure: (error) {
          _setGlobalError(error);
        },
      );
    } catch (e) {
      _setGlobalError(UnknownError(e.toString()));
    }
  }

  /// Reset password for given email
  Future<void> resetPassword(String email) async {
    _clearGlobalError();
    
    try {
      final result = await _resetPasswordUseCase.call(
        ResetPasswordParams(email: email),
      );
      result.when(
        success: (_) {
          // Password reset email sent successfully
          _globalError = null;
        },
        failure: (error) {
          _setGlobalError(error);
        },
      );
    } catch (e) {
      _setGlobalError(UnknownError(e.toString()));
    }
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

  // Command listeners
  void _onSignInCommandChanged() {
    if (_signInCommand.isCompleted && _signInCommand.result != null) {
      _currentSession = _signInCommand.result;
      _clearSignupState();
      
      // Trigger profile loading after successful sign in
      _triggerProfileLoad();
      
      notifyListeners();
    }
  }

  void _onSignUpCommandChanged() {
    if (_signUpCommand.isCompleted && _signUpCommand.result != null) {
      _signupToken = _signUpCommand.result;
      notifyListeners();
    }
  }

  void _onCompleteSignupCommandChanged() {
    if (_completeSignupCommand.isCompleted && _completeSignupCommand.result != null) {
      _currentSession = _completeSignupCommand.result;
      _clearSignupState();
      
      // Trigger profile loading after successful signup completion
      _triggerProfileLoad();
      
      notifyListeners();
    }
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

  /// Trigger profile loading after successful authentication
  void _triggerProfileLoad() {
    try {
      final profileViewModel = serviceLocator<ProfileViewModel>();
      // Trigger profile load asynchronously
      Future.microtask(() => profileViewModel.loadProfile());
    } catch (e) {
      // If ProfileViewModel is not available, continue without error
      // This prevents auth flow from breaking if profile feature is not available
      debugPrint('ProfileViewModel not available for auto-loading: $e');
    }
  }

  @override
  void dispose() {
    _signInCommand.removeListener(_onSignInCommandChanged);
    _signUpCommand.removeListener(_onSignUpCommandChanged);
    _completeSignupCommand.removeListener(_onCompleteSignupCommandChanged);
    
    _signInCommand.dispose();
    _signUpCommand.dispose();
    _completeSignupCommand.dispose();
    
    super.dispose();
  }
}