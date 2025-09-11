import 'dart:io';

import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';

import '../../../../api/extensions.dart';
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
      final response =
          await _api.getUserProfileApi().userModelsApiGetUserProfile();

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('Profile loading failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 404) {
          throw ApiException('Profile not found');
        }
        throw NetworkException('Network error: ${e.message}');
      }
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
        throw ApiException('Profile update failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 400) {
          throw ValidationException('Invalid profile data');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many requests. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Profile update failed: ${e.toString()}');
    }
  }

  @override
  Future<String> uploadProfilePicture(File imageFile) async {
    try {
      // Create multipart file for upload
      final multipartFile = await MultipartFile.fromFile(
        imageFile.path,
        filename: 'profile_picture.${imageFile.path.split('.').last}',
      );

      final response = await _api
          .getUserProfileApi()
          .userModelsApiUpdateProfilePicture(profilePicture: multipartFile);

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('Profile picture upload failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 413) {
          throw ValidationException('Image file is too large');
        } else if (e.response?.statusCode == 415) {
          throw ValidationException('Unsupported image format');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many requests. Please wait before trying again.',
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
      // Create multipart file for upload
      final multipartFile = await MultipartFile.fromFile(
        cvFile.path,
        filename: 'cv.${cvFile.path.split('.').last}',
      );

      final response = await _api.getUserProfileApi().userModelsApiUpdateCv(
        cv: multipartFile,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('CV upload failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 413) {
          throw ValidationException('CV file is too large');
        } else if (e.response?.statusCode == 415) {
          throw ValidationException('Unsupported file format');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many requests. Please wait before trying again.',
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
      final response =
          await _api.getUserProfileApi().userModelsApiDeleteProfilePicture();

      if (!response.isSuccess) {
        throw ApiException(
          'Profile picture deletion failed: ${response.error}',
        );
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 404) {
          throw ApiException('Profile picture not found');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many requests. Please wait before trying again.',
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
        throw ApiException('CV deletion failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        } else if (e.response?.statusCode == 404) {
          throw ApiException('CV not found');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many requests. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('CV deletion failed: ${e.toString()}');
    }
  }
}
