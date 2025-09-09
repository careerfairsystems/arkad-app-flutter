import 'dart:io';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/exception.dart';
import '../../domain/entities/file_upload_result.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/programme.dart';
import '../../domain/repositories/profile_repository.dart';
import '../data_sources/profile_local_data_source.dart';
import '../data_sources/profile_remote_data_source.dart';
import '../mappers/profile_mapper.dart';

/// Implementation of profile repository
class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in getCurrentProfile: ${e.message}',
        level: SentryLevel.info,
      ));
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in getCurrentProfile: ${e.message}',
        level: SentryLevel.info,
      ));
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in updateProfile: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Validation error in updateProfile: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile update failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in updateProfile: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Rate limit hit in updateProfile: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(RateLimitError(const Duration(minutes: 2)));
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
      final fileUrl = await _remoteDataSource.uploadProfilePicture(imageFile);
      
      final result = FileUploadResult(
        fileName: imageFile.path.split('/').last,
        fileUrl: fileUrl,
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in uploadProfilePicture: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Validation error in uploadProfilePicture: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile picture upload failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in uploadProfilePicture: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('413')) {
        // File too large is expected validation error - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Image file too large in uploadProfilePicture: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(const ValidationError("Image file is too large (max 5MB)"));
      } else if (e.message.contains('415')) {
        // Unsupported format is expected validation error - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Unsupported image format in uploadProfilePicture: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(const ValidationError("Unsupported image format"));
      } else if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Rate limit hit in uploadProfilePicture: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(RateLimitError(const Duration(minutes: 2)));
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
      final fileUrl = await _remoteDataSource.uploadCV(cvFile);
      
      final result = FileUploadResult(
        fileName: cvFile.path.split('/').last,
        fileUrl: fileUrl,
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in uploadCV: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ProfileLoadingError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Validation error in uploadCV: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'CV upload failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in uploadCV: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('413')) {
        // File too large is expected validation error - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'CV file too large in uploadCV: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(const ValidationError("CV file is too large (max 10MB)"));
      } else if (e.message.contains('415')) {
        // Unsupported format is expected validation error - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Unsupported file format in uploadCV: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(const ValidationError("Unsupported file format"));
      } else if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Rate limit hit in uploadCV: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(RateLimitError(const Duration(minutes: 2)));
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in deleteProfilePicture: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Profile picture deletion failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in deleteProfilePicture: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Rate limit hit in deleteProfilePicture: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(RateLimitError(const Duration(minutes: 2)));
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
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Auth exception in deleteCV: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'CV deletion failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'Network exception in deleteCV: ${e.message}',
        level: SentryLevel.info,
      ));
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(Breadcrumb(
          message: 'Rate limit hit in deleteCV: ${e.message}',
          level: SentryLevel.info,
        ));
        return Result.failure(RateLimitError(const Duration(minutes: 2)));
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
      if (!_isValidLinkedInUrl(profile.linkedin!)) {
        return Result.failure(const ValidationError("Please enter a valid LinkedIn profile URL"));
      }
    }

    // Validate study year if provided
    if (profile.studyYear != null) {
      if (profile.studyYear! < 1 || profile.studyYear! > 10) {
        return Result.failure(const ValidationError("Study year must be between 1 and 10"));
      }
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
      suggestions.add("Add your LinkedIn profile to showcase your professional network");
    }
    if (profile.programme == null) {
      suggestions.add("Select your study programme to help companies find relevant candidates");
    }
    if (profile.studyYear == null) {
      suggestions.add("Add your study year to help companies understand your experience level");
    }
    
    return suggestions;
  }

  bool _isValidLinkedInUrl(String url) {
    // Accept LinkedIn URLs in various formats
    final patterns = [
      r'^https://www\.linkedin\.com/in/[\w\-]+/?$',
      r'^https://linkedin\.com/in/[\w\-]+/?$',
      r'^www\.linkedin\.com/in/[\w\-]+/?$',
      r'^linkedin\.com/in/[\w\-]+/?$',
    ];

    return patterns.any((pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url));
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