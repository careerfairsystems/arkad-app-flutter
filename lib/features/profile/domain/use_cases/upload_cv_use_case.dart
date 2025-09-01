import 'dart:io';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/file_upload_result.dart';
import '../repositories/profile_repository.dart';

/// Use case for uploading CV document
class UploadCVUseCase extends UseCase<FileUploadResult, UploadCVParams> {
  const UploadCVUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<FileUploadResult>> call(UploadCVParams params) async {
    // Validate file
    final validation = _validateCVFile(params.cvFile);
    if (validation.isFailure) {
      return Result.failure(validation.errorOrNull!);
    }

    // Upload CV
    return await _repository.uploadCV(params.cvFile);
  }

  Result<void> _validateCVFile(File cvFile) {
    // Check if file exists
    if (!cvFile.existsSync()) {
      return Result.failure(
        const ValidationError("Selected CV file does not exist"),
      );
    }

    // Check file size (max 10MB)
    final sizeInBytes = cvFile.lengthSync();
    const maxSizeInBytes = 10 * 1024 * 1024; // 10MB
    if (sizeInBytes > maxSizeInBytes) {
      return Result.failure(
        const ValidationError("CV must be smaller than 10MB"),
      );
    }

    // Check file extension
    final extension = cvFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['pdf', 'doc', 'docx'];
    if (!allowedExtensions.contains(extension)) {
      return Result.failure(
        const ValidationError("CV must be PDF, DOC, or DOCX format"),
      );
    }

    return Result.success(null);
  }
}

/// Parameters for upload CV use case
class UploadCVParams {
  const UploadCVParams({
    required this.cvFile,
  });

  final File cvFile;
}