import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/infrastructure/services/file_validation_service.dart';
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

      // Comprehensive file validation using FileValidationService
      final file = File(params.filePath);
      final validationResult = await FileValidationService.validateCVFile(file);

      return await validationResult.when(
        success: (_) async {
          // File is valid, proceed with upload
          return await _repository.uploadCVForSession(
            companyId: params.companyId,
            filePath: params.filePath,
          );
        },
        failure: (validationError) async {
          // Convert ValidationError to StudentSessionApplicationError for consistency
          return Result.failure(
            StudentSessionApplicationError(validationError.userMessage),
          );
        },
      );
    } catch (e, stackTrace) {
      // Enhanced Sentry reporting with context
      await Sentry.captureException(e, stackTrace: stackTrace);
      Sentry.logger.error(
        'CV upload failed',
        attributes: {
          'operation': SentryLogAttribute.string('uploadCV'),
          'company_id': SentryLogAttribute.string(params.companyId.toString()),
          'error_type': SentryLogAttribute.string(e.runtimeType.toString()),
        },
      );

      // Check if it's a file size error or other upload error
      final errorString = e.toString();
      if (errorString.contains('size') || errorString.contains('413')) {
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
          details: 'Failed to upload CV. Please try again.',
        ),
      );
    }
  }
}
