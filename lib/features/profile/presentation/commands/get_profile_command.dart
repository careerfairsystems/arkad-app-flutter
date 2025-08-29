import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/get_current_profile_use_case.dart';

/// Command for loading current user profile
class GetProfileCommand extends ChangeNotifier {
  final GetCurrentProfileUseCase _useCase;

  bool _isRunning = false;
  bool _isCompleted = false;
  AppError? _error;
  Profile? _result;

  GetProfileCommand(this._useCase);

  // State getters
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  AppError? get error => _error;
  Profile? get result => _result;

  /// Execute the command to load current profile
  Future<void> execute() async {
    _isRunning = true;
    _isCompleted = false;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final result = await _useCase();
      
      result.when(
        success: (profile) {
          _result = profile;
          _isCompleted = true;
        },
        failure: (error) {
          _error = error;
        },
      );
    } catch (e) {
      _error = UnknownError('Failed to load profile: $e');
    } finally {
      _isRunning = false;
      notifyListeners();
    }
  }

  /// Reset command state
  void reset() {
    _isRunning = false;
    _isCompleted = false;
    _error = null;
    _result = null;
    notifyListeners();
  }
}