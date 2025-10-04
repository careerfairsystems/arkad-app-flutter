import 'dart:io';

import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';
import '../../../../shared/errors/exception.dart';

/// Abstract interface for profile remote data source
abstract class ProfileRemoteDataSource {
  Future<ProfileSchema> getUserProfile();
  Future<ProfileSchema> updateProfile(UpdateProfileSchema updateData);
  Future<String> uploadProfilePicture(File imageFile);
  Future<String> uploadCV(File cvFile);
  Future<void> deleteProfilePicture();
  Future<void> deleteCV();
}

/// Implementation of profile remote data source using auto-generated API client
class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  const ProfileRemoteDataSourceImpl(this._api);

  final ArkadApi _api;

  @override
  Future<ProfileSchema> getUserProfile() async {
    try {
      final response = await _api
          .getUserProfileApi()
          .userModelsApiGetUserProfile();

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('getUserProfile');
        throw ApiException('Profile loading failed: ${response.detailedError}');
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getUserProfile',
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw ApiException('Profile loading failed: ${e.toString()}');
    }
  }

  @override
  Future<ProfileSchema> updateProfile(UpdateProfileSchema updateData) async {
    try {
      final response = await _api
          .getUserProfileApi()
          .userModelsApiUpdateProfile(updateProfileSchema: updateData);

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('updateProfile');
        throw ApiException('Profile update failed: ${response.detailedError}');
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'updateProfile',
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw ApiException('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      // Create multipart file for upload using platform-appropriate method
      MultipartFile multipartFile;

      if (kIsWeb) {
        // On web, read bytes and create multipart file from bytes
        final bytes = await imageFile.readAsBytes();
        final filename = imageFile.path.split('/').last;
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.isNotEmpty ? filename : 'profile_picture.jpg',
        );
      } else {
        // On mobile, use the traditional path-based approach
        multipartFile = await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_picture.${imageFile.path.split('.').last}',
        );
      }

      final response = await _api
          .getUserProfileApi()
          .userModelsApiUpdateProfilePicture(profilePicture: multipartFile);

      if (response.isSuccess) {
        return 'success'; // Return success indicator, not a URL
      } else {
        throw ApiException(
          'Profile picture upload failed: ${response.error}',
          response.statusCode,
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const AuthException('Authentication required');
        } else if (statusCode == 413) {
          throw const ValidationException('Image file is too large');
        } else if (statusCode == 415) {
          throw const ValidationException('Unsupported image format');
        } else if (statusCode == 429) {
          throw const ApiException(
            'Too many requests. Please wait before trying again.',
            429,
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Profile picture upload failed: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadCV(File cvFile) async {
    try {
      // Create multipart file for upload using platform-appropriate method
      MultipartFile multipartFile;

      if (kIsWeb) {
        // On web, read bytes and create multipart file from bytes
        final bytes = await cvFile.readAsBytes();
        final filename = cvFile.path.split('/').last;
        multipartFile = MultipartFile.fromBytes(
          bytes,
          filename: filename.isNotEmpty ? filename : 'cv.pdf',
        );
      } else {
        // On mobile, use the traditional path-based approach
        multipartFile = await MultipartFile.fromFile(
          cvFile.path,
          filename: 'cv.${cvFile.path.split('.').last}',
        );
      }

      final response = await _api.getUserProfileApi().userModelsApiUpdateCv(
        cv: multipartFile,
      );

      if (response.isSuccess) {
        return 'success'; // Return success indicator, not a URL
      } else {
        throw ApiException(
          'CV upload failed: ${response.error}',
          response.statusCode,
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const AuthException('Authentication required');
        } else if (statusCode == 413) {
          throw const ValidationException('CV file is too large');
        } else if (statusCode == 415) {
          throw const ValidationException('Unsupported file format');
        } else if (statusCode == 429) {
          throw const ApiException(
            'Too many requests. Please wait before trying again.',
            429,
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('CV upload failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteProfilePicture() async {
    try {
      final response = await _api
          .getUserProfileApi()
          .userModelsApiDeleteProfilePicture();

      if (!response.isSuccess) {
        throw ApiException(
          'Profile picture deletion failed: ${response.error}',
          response.statusCode,
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const AuthException('Authentication required');
        } else if (statusCode == 404) {
          throw const ApiException('Profile picture not found', 404);
        } else if (statusCode == 429) {
          throw const ApiException(
            'Too many requests. Please wait before trying again.',
            429,
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Profile picture deletion failed: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteCV() async {
    try {
      final response = await _api.getUserProfileApi().userModelsApiDeleteCv();

      if (!response.isSuccess) {
        throw ApiException(
          'CV deletion failed: ${response.error}',
          response.statusCode,
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const AuthException('Authentication required');
        } else if (statusCode == 404) {
          throw const ApiException('CV not found', 404);
        } else if (statusCode == 429) {
          throw const ApiException(
            'Too many requests. Please wait before trying again.',
            429,
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('CV deletion failed: ${e.toString()}');
    }
  }
}
