import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/exception.dart';
import '../../../../shared/infrastructure/services/file_validation_service.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/programme.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_local_data_source.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../mappers/profile_mapper.dart';

/// Implementation of profile repository
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;

  @override
  Future<Result<Profile>> getCurrentProfile() async {
    try {
      // Try to get from remote first to ensure fresh data
      final profileDto = await _remoteDataSource.getUserProfile();
      final profile = ProfileMapper.fromDto(profileDto);

      // Cache locally for offline access
      await _localDataSource.saveProfile(profile);

      return Result.success(profile);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Profile loading failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      // If auth fails, try local cache
      try {
        final cachedProfile = await _localDataSource.getProfile();
        if (cachedProfile != null) {
          return Result.success(cachedProfile);
        }
        return Result.failure(ProfileLoadingError(details: e.message));
      } catch (localError, stackTrace) {
        await Sentry.captureException(localError, stackTrace: stackTrace);
        return Result.failure(ProfileLoadingError(details: e.message));
      }
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile loading failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      // If network fails, try local cache
      try {
        final cachedProfile = await _localDataSource.getProfile();
        if (cachedProfile != null) {
          return Result.success(cachedProfile);
        }
        return Result.failure(NetworkError(details: e.message));
      } catch (localError, stackTrace) {
        await Sentry.captureException(localError, stackTrace: stackTrace);
        return Result.failure(NetworkError(details: e.message));
      }
    } on ApiException catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<Profile>> updateProfile(Profile profile) async {
    try {
      // Validate profile before update
      final validation = validateProfile(profile);
      if (validation.isFailure) {
        return Result.failure(validation.errorOrNull!);
      }

      // Update via remote API
      final updateDto = ProfileMapper.toUpdateDto(profile);
      final updatedDto = await _remoteDataSource.updateProfile(updateDto);
      final updatedProfile = ProfileMapper.fromDto(updatedDto);

      // Cache updated profile locally
      await _localDataSource.saveProfile(updatedProfile);

      return Result.success(updatedProfile);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Profile update failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile update failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 2)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<FileUploadResult>> uploadProfilePicture(File imageFile) async {
    try {
      // Proactive file validation before sending to server
      final validation = await FileValidationService.validateProfilePicture(
        imageFile,
      );
      if (validation.isFailure) {
        return Result.failure(validation.errorOrNull!);
      }

      await _remoteDataSource.uploadProfilePicture(imageFile);

      final result = FileUploadResult(
        fileName: imageFile.path.split('/').last,
        fileUrl: '', // Empty URL - will be populated after profile refresh
        fileSize: await imageFile.length(),
        uploadedAt: DateTime.now(),
        mimeType: _getMimeType(imageFile.path),
      );

      return Result.success(result);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Profile picture upload failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile picture upload failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('413')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(
          const ValidationError(
            "Image file is too large (server limit exceeded)",
          ),
        );
      } else if (e.message.contains('415')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(
          const ValidationError("Unsupported image format"),
        );
      } else if (e.message.contains('429')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 2)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<FileUploadResult>> uploadCV(File cvFile) async {
    try {
      // Proactive file validation before sending to server
      final validation = await FileValidationService.validateCVFile(cvFile);
      if (validation.isFailure) {
        return Result.failure(validation.errorOrNull!);
      }

      await _remoteDataSource.uploadCV(cvFile);

      final result = FileUploadResult(
        fileName: cvFile.path.split('/').last,
        fileUrl: '', // Empty URL - will be populated after profile refresh
        fileSize: await cvFile.length(),
        uploadedAt: DateTime.now(),
        mimeType: _getMimeType(cvFile.path),
      );

      return Result.success(result);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'CV upload failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'CV upload failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('413')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(
          const ValidationError("CV file is too large (server limit exceeded)"),
        );
      } else if (e.message.contains('415')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const ValidationError("Unsupported file format"));
      } else if (e.message.contains('429')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 2)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteProfilePicture() async {
    try {
      await _remoteDataSource.deleteProfilePicture();
      return Result.success(null);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Profile picture deletion failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile picture deletion failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 2)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteCV() async {
    try {
      await _remoteDataSource.deleteCV();
      return Result.success(null);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'CV deletion failed - authentication required',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'CV deletion failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 2)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  List<String> getAvailableProgrammeLabels() {
    return ProgrammeUtils.allProgrammeLabels;
  }

  @override
  Result<void> validateProfile(Profile profile) {
    // Validate required fields
    if (profile.firstName.isEmpty) {
      return Result.failure(const ValidationError("First name is required"));
    }
    if (profile.lastName.isEmpty) {
      return Result.failure(const ValidationError("Last name is required"));
    }

    // Validate LinkedIn URL if provided
    if (profile.linkedin != null && profile.linkedin!.isNotEmpty) {
      if (!ValidationService.isValidLinkedInUrl(profile.linkedin!)) {
        return Result.failure(
          const ValidationError(
            "Please enter a valid LinkedIn URL (e.g., https://www.linkedin.com/in/yourname)",
          ),
        );
      }
    }

    // Validate study year if provided
    if (!ValidationService.isValidStudyYear(profile.studyYear)) {
      return Result.failure(
        const ValidationError("Study year must be between 1 and 5 (inclusive)"),
      );
    }

    return Result.success(null);
  }

  @override
  List<String> getCompletionSuggestions(Profile profile) {
    final suggestions = <String>[];

    if (!profile.hasProfilePicture) {
      suggestions.add("Add a profile picture to help companies recognize you");
    }
    if (!profile.hasCV) {
      suggestions.add("Upload your CV to apply for student sessions");
    }
    if (!profile.hasLinkedIn) {
      suggestions.add(
        "Add your LinkedIn profile URL to showcase your professional network",
      );
    }
    if (profile.programme == null) {
      suggestions.add(
        "Select your study programme to help companies find relevant candidates",
      );
    }
    if (profile.studyYear == null) {
      suggestions.add(
        "Add your study year to help companies understand your experience level",
      );
    }

    return suggestions;
  }

  String? _getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }
}
