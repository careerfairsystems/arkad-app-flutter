import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/update_profile_use_case.dart';

/// Command for updating user profile
class UpdateProfileCommand extends ChangeNotifier {
  final UpdateProfileUseCase _useCase;

  bool _isRunning = false;
  bool _isCompleted = false;
  AppError? _error;
  Profile? _result;

  UpdateProfileCommand(this._useCase);

  // State getters
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  AppError? get error => _error;
  Profile? get result => _result;

  /// Execute the command to update profile
  Future<bool> execute(Profile profile) async {
    _isRunning = true;
    _isCompleted = false;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final params = UpdateProfileParams(profile: profile);
      final result = await _useCase(params);
      
      return result.when(
        success: (updatedProfile) {
          _result = updatedProfile;
          _isCompleted = true;
          notifyListeners();
          return true;
        },
        failure: (error) {
          _error = error;
          notifyListeners();
          return false;
        },
      );
    } catch (e) {
      _error = UnknownError('Failed to update profile: $e');
      notifyListeners();
      return false;
    } finally {
      _isRunning = false;
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