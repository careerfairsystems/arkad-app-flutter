import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';

/// Command for complete signup operation
class CompleteSignupCommand extends ChangeNotifier {
  CompleteSignupCommand(this._completeSignupUseCase);

  final CompleteSignupUseCase _completeSignupUseCase;

  bool _isExecuting = false;
  AppError? _error;
  AuthSession? _result;

  // Getters
  bool get isExecuting => _isExecuting;
  AppError? get error => _error;
  AuthSession? get result => _result;
  bool get hasError => _error != null;
  bool get isCompleted => _result != null && !_isExecuting;

  /// Execute complete signup command
  Future<void> execute({
    required String signupToken,
    required String verificationCode,
    required SignupData signupData,
  }) async {
    if (_isExecuting) return; // Prevent multiple concurrent executions

    _setExecuting(true);
    _clearError();
    _result = null;

    final result = await _completeSignupUseCase.call(
      CompleteSignupParams(
        signupToken: signupToken,
        verificationCode: verificationCode,
        signupData: signupData,
      ),
    );

    result.when(
      success: (session) {
        _result = session;
        _error = null;
      },
      failure: (error) {
        _error = error;
        _result = null;
      },
    );

    _setExecuting(false);
  }

  /// Clear any existing error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Reset the command state
  void reset() {
    _isExecuting = false;
    _error = null;
    _result = null;
    notifyListeners();
  }

  void _setExecuting(bool executing) {
    _isExecuting = executing;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}