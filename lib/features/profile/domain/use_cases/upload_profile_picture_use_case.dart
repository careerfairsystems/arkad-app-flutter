import 'dart:io';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/file_upload_result.dart';
import '../repositories/profile_repository.dart';

/// Use case for uploading profile picture
class UploadProfilePictureUseCase
    extends UseCase<FileUploadResult, UploadProfilePictureParams> {
  const UploadProfilePictureUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<FileUploadResult>> call(
    UploadProfilePictureParams params,
  ) async {
    // Validate file
    final validation = _validateImageFile(params.imageFile);
    if (validation.isFailure) {
      return Result.failure(validation.errorOrNull!);
    }

    // Upload image
    return await _repository.uploadProfilePicture(params.imageFile);
  }

  Result<void> _validateImageFile(File imageFile) {
    // Check if file exists
    if (!imageFile.existsSync()) {
      return Result.failure(
        const ValidationError("Selected image file does not exist"),
      );
    }

    // Check file size (max 5MB)
    final sizeInBytes = imageFile.lengthSync();
    const maxSizeInBytes = 5 * 1024 * 1024; // 5MB
    if (sizeInBytes > maxSizeInBytes) {
      return Result.failure(
        const ValidationError("Image must be smaller than 5MB"),
      );
    }

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    const allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      return Result.failure(
        const ValidationError("Image must be JPG, PNG, or WebP format"),
      );
    }

    return Result.success(null);
  }
}

/// Parameters for upload profile picture use case
class UploadProfilePictureParams {
  const UploadProfilePictureParams({required this.imageFile});

  final File imageFile;
}
