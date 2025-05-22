import '../utils/sentry_utils.dart';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'api_service.dart';

/// Service for handling user profile data and operations
class UserService {
  static const String _profilePictureField = 'profile_picture';
  static const String _cvField = 'cv';

  final AuthService _authService;
  final ApiService _apiService;

  UserService({
    required AuthService authService,
    required ApiService apiService,
  }) : _authService = authService,
       _apiService = apiService;

  /// Retrieves the current user's profile
  Future<User> getUserProfile() async {
    try {
      final token = await _getAuthToken();

      final response = await _apiService.get(
        ApiEndpoints.userProfile,
        headers: {'Authorization': token},
        fromJson: User.fromJson,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw UserException('Failed to get user profile: ${response.error}');
      }
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error retrieving user profile: ${e.toString()}');
    }
  }

  /// Updates the entire profile at once
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final token = await _getAuthToken();

      final response = await _apiService.put(
        ApiEndpoints.userProfile,
        headers: {'Authorization': token},
        body: profileData,
        fromJson: User.fromJson,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw UserException('Failed to update profile: ${response.error}');
      }
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error updating profile: ${e.toString()}');
    }
  }

  /// Updates specified profile fields
  Future<User> updateProfileFields(Map<String, dynamic> fields) async {
    try {
      final token = await _getAuthToken();

      final response = await _apiService.patch(
        ApiEndpoints.userProfile,
        headers: {'Authorization': token},
        body: fields,
        fromJson: User.fromJson,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw UserException(
          'Failed to update profile fields: ${response.error}',
        );
      }
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error updating profile fields: ${e.toString()}');
    }
  }

  /// Uploads a profile picture
  Future<bool> uploadProfilePicture(File imageFile) async {
    try {
      return await _uploadFile(
        imageFile,
        ApiEndpoints.profilePicture,
        _profilePictureField,
      );
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error uploading profile picture: ${e.toString()}');
    }
  }

  /// Deletes the current profile picture
  Future<bool> deleteProfilePicture() async {
    try {
      final token = await _getAuthToken();

      final response = await _apiService.delete(
        ApiEndpoints.profilePicture,
        headers: {'Authorization': token},
      );

      return response.isSuccess;
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error deleting profile picture: ${e.toString()}');
    }
  }

  /// Uploads a CV file
  Future<bool> uploadCV(File cvFile) async {
    try {
      return await _uploadFile(cvFile, ApiEndpoints.cv, _cvField);
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error uploading CV: ${e.toString()}');
    }
  }

  /// Deletes the current CV
  Future<bool> deleteCV() async {
    try {
      final token = await _getAuthToken();

      final response = await _apiService.delete(
        ApiEndpoints.cv,
        headers: {'Authorization': token},
      );

      return response.isSuccess;
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error deleting CV: ${e.toString()}');
    }
  }

  // Private helper methods

  /// Gets the auth token or throws an exception if not available
  Future<String> _getAuthToken() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw UserException('Not authenticated');
    }
    return token;
  }

  /// Generic file upload method to handle both CV and profile picture uploads
  Future<bool> _uploadFile(File file, String endpoint, String fieldName) async {
    try {
      // Create a multipart request
      final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      // Add JWT authorization
      final token = await _getAuthToken();
      request.headers['Authorization'] = token;

      // Determine mime type
      final mimeType =
          lookupMimeType(file.path) ??
          (fieldName == _profilePictureField
              ? 'image/jpeg'
              : 'application/pdf');
      final fileType = mimeType.split('/');

      // Add the file
      final fileBytes = await file.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        fieldName,
        fileBytes,
        filename: file.path.split('/').last,
        contentType: MediaType(fileType[0], fileType[1]),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return true;
      } else {
        throw UserException('Failed to upload file: ${response.body}');
      }
    } catch (e, stackTrace) {
      if (e is UserException) rethrow;
      SentryUtils.captureException(e, stackTrace: stackTrace);
      throw UserException('Error uploading file: ${e.toString()}');
    }
  }
}

/// Custom exception class for user-related errors
class UserException implements Exception {
  final String message;

  UserException(this.message);

  @override
  String toString() => message;
}
