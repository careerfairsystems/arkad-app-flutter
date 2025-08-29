import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/use_cases/upload_cv_use_case.dart';

/// Command for uploading CV file
class UploadCVCommand extends ChangeNotifier {
  final UploadCVUseCase _useCase;

  bool _isRunning = false;
  bool _isCompleted = false;
  AppError? _error;
  FileUploadResult? _uploadResult;

  UploadCVCommand(this._useCase);

  // State getters
  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  AppError? get error => _error;
  FileUploadResult? get uploadResult => _uploadResult;

  /// Execute the command to upload CV
  Future<bool> execute(File file) async {
    _isRunning = true;
    _isCompleted = false;
    _error = null;
    _uploadResult = null;
    notifyListeners();

    try {
      final params = UploadCVParams(cvFile: file);
      final result = await _useCase(params);
      
      return result.when(
        success: (uploadResult) {
          _uploadResult = uploadResult;
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
      _error = UnknownError('Failed to upload CV: $e');
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
    _uploadResult = null;
    notifyListeners();
  }
}