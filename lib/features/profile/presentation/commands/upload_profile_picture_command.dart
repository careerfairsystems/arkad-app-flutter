import 'dart:io';

import '../../../../shared/presentation/commands/result_command.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/use_cases/upload_profile_picture_use_case.dart';

/// Command for uploading profile picture
class UploadProfilePictureCommand
    extends
        ParameterizedResultCommand<
          UploadProfilePictureParams,
          FileUploadResult
        > {
  final UploadProfilePictureUseCase _useCase;

  UploadProfilePictureCommand(this._useCase);

  // Convenience getter for upload result
  FileUploadResult? get uploadResult => result;

  @override
  Future<bool> executeForResultWithParams(
    UploadProfilePictureParams params,
  ) async {
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
  Future<bool> uploadProfilePicture(File file) async {
    return await executeForResultWithParams(
      UploadProfilePictureParams(imageFile: file),
    );
  }
}
