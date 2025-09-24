import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../repositories/student_session_repository.dart';

/// Parameters for uploading CV
class UploadCVParams {
  const UploadCVParams({required this.companyId, required this.filePath});

  final int companyId;
  final String filePath;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadCVParams &&
        other.companyId == companyId &&
        other.filePath == filePath;
  }

  @override
  int get hashCode => Object.hash(companyId, filePath);

  @override
  String toString() {
    final fileName = filePath.split('/').last;
    return 'UploadCVParams(companyId: $companyId, fileName: $fileName)';
  }
}

/// Use case for uploading CV file for student session application
class UploadCVUseCase extends UseCase<String, UploadCVParams> {
  const UploadCVUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(UploadCVParams params) async {
    try {
      // Validate parameters
      if (params.companyId <= 0) {
        return Result.failure(
          const StudentSessionApplicationError('Invalid company ID.'),
        );
      }

      if (params.filePath.isEmpty) {
        return Result.failure(
          const StudentSessionApplicationError(
            'No file selected. Please select a CV file to upload.',
          ),
        );
      }

      // Check file extension (basic validation)
      final validExtensions = ['.pdf', '.doc', '.docx'];
      final hasValidExtension = validExtensions.any(
        (ext) => params.filePath.toLowerCase().endsWith(ext),
      );

      if (!hasValidExtension) {
        return Result.failure(
          const StudentSessionApplicationError(
            'Invalid file type. Please upload a PDF, DOC, or DOCX file.',
          ),
        );
      }

      // Upload CV through repository
      return await _repository.uploadCVForSession(
        companyId: params.companyId,
        filePath: params.filePath,
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      
      // Check if it's a file size error or other upload error
      if (e.toString().contains('size') || e.toString().contains('413')) {
        return Result.failure(
          StudentSessionFileUploadError(
            params.filePath.split('/').last,
            details: 'File is too large. Maximum size is 10MB.',
          ),
        );
      }

      return Result.failure(
        StudentSessionFileUploadError(
          params.filePath.split('/').last,
          details: e.toString(),
        ),
      );
    }
  }
}
