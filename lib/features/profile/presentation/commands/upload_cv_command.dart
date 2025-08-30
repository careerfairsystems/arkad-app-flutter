import 'dart:io';

import '../../../../shared/presentation/commands/result_command.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/use_cases/upload_cv_use_case.dart';

/// Command for uploading CV file
class UploadCVCommand extends ParameterizedResultCommand<UploadCVParams, FileUploadResult> {
  final UploadCVUseCase _useCase;

  UploadCVCommand(this._useCase);

  // Convenience getter for upload result
  FileUploadResult? get uploadResult => result;

  @override
  Future<bool> executeForResultWithParams(UploadCVParams params) async {
    if (isExecuting) return false;

    setExecuting(true);

    final result = await _useCase(params);
    
    final success = result.when(
      success: (uploadResult) {
        setResult(uploadResult);
        return true;
      },
      failure: (error) {
        setError(error);
        return false;
      },
    );

    setExecuting(false);
    return success;
  }

  /// Convenience method for executing with file
  Future<bool> uploadCV(File file) async {
    return await executeForResultWithParams(UploadCVParams(cvFile: file));
  }
}