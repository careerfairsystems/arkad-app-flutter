import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/result_command.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/use_cases/upload_cv_use_case.dart';

/// Command for uploading CV file
class UploadCVCommand
    extends ParameterizedResultCommand<UploadCVParams, FileUploadResult> {
  final UploadCVUseCase _useCase;

  UploadCVCommand(this._useCase);

  // Convenience getter for upload result
  FileUploadResult? get uploadResult => result;

  @override
  Future<bool> executeForResultWithParams(UploadCVParams params) async {
    if (isExecuting) return false;

    clearError(); 
    setExecuting(true);

    try {
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

      return success;
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(e, null, operationContext: 'upload_cv'),
        );
      } else {
        setError(UnknownError(e.toString()));
      }
      return false;
    } finally {
      setExecuting(false); 
    }
  }

  /// Convenience method for executing with file
  Future<bool> uploadCV(File file) async {
    return await executeForResultWithParams(UploadCVParams(cvFile: file));
  }
}
