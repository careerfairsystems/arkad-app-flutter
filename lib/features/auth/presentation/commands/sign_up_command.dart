import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/sign_up_use_case.dart';

/// Command for sign up operation
class SignUpCommand extends ChangeNotifier {
  SignUpCommand(this._signUpUseCase);

  final SignUpUseCase _signUpUseCase;

  bool _isExecuting = false;
  AppError? _error;
  String? _result;

  // Getters
  bool get isExecuting => _isExecuting;
  AppError? get error => _error;
  String? get result => _result; // Returns signup token
  bool get hasError => _error != null;
  bool get isCompleted => _result != null && !_isExecuting;

  /// Execute sign up command
  Future<void> execute(SignupData signupData) async {
    if (_isExecuting) return; // Prevent multiple concurrent executions

    _setExecuting(true);
    _clearError();
    _result = null;

    final result = await _signUpUseCase.call(signupData);

    result.when(
      success: (token) {
        _result = token;
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