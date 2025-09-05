import 'package:flutter/foundation.dart';

import '../../errors/app_error.dart';

/// Abstract base class for all commands in the application
/// Provides consistent state management and error handling
abstract class Command<T> extends ChangeNotifier {
  bool _isExecuting = false;
  AppError? _error;
  T? _result;
  bool _hasBeenExecuted = false;

  // State getters
  bool get isExecuting => _isExecuting;
  bool get hasError => _error != null;
  bool get isCompleted => _hasBeenExecuted && !_isExecuting && _error == null;
  bool get isIdle => !_hasBeenExecuted && !_isExecuting && _error == null;
  
  AppError? get error => _error;
  T? get result => _result;

  /// Execute the command - to be implemented by subclasses
  Future<void> execute();

  /// Protected method to update execution state
  @protected
  void setExecuting(bool executing) {
    if (_isExecuting != executing) {
      _isExecuting = executing;
      if (executing) {
        _hasBeenExecuted = true;
      }
      notifyListeners();
    }
  }

  /// Protected method to set the result
  @protected
  void setResult(T? result) {
    _result = result;
    _error = null;
    notifyListeners();
  }

  /// Protected method to set an error
  @protected
  void setError(AppError error) {
    _error = error;
    _result = null;
    notifyListeners();
  }

  /// Clear any existing error
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  /// Reset the command to its initial state
  void reset({bool notify = true}) {
    _isExecuting = false;
    _error = null;
    _result = null;
    _hasBeenExecuted = false;
    if (notify) notifyListeners();
  }

  @override
  void dispose() {
    reset(notify: false);
    super.dispose();
  }
}

/// Command for operations that don't return a result
abstract class VoidCommand extends Command<void> {
  bool get isSuccessful => isCompleted;
}

/// Command for operations with parameters
abstract class ParameterizedCommand<TParams, TResult> extends Command<TResult> {
  /// Execute the command with parameters
  Future<void> executeWithParams(TParams params);

  @override
  Future<void> execute() async {
    throw UnsupportedError('Use executeWithParams instead');
  }
}