import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import 'api_service.dart';

class UserService {
  final AuthService _authService;
  final ApiService _apiService;

  UserService({
    required AuthService authService,
    required ApiService apiService,
  }) : _authService = authService,
       _apiService = apiService;

  // Get user profile
  Future<User> getUserProfile() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _apiService.get(
      ApiEndpoints.userProfile,
      headers: {'Authorization': token},
      fromJson: User.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Failed to get user profile: ${response.error}');
    }
  }

  // Update complete profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _apiService.put(
      ApiEndpoints.userProfile,
      headers: {'Authorization': token},
      body: profileData,
      fromJson: User.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Failed to update profile: ${response.error}');
    }
  }

  // Update individual profile fields
  Future<User> updateProfileFields(Map<String, dynamic> fields) async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _apiService.patch(
      ApiEndpoints.userProfile,
      headers: {'Authorization': token},
      body: fields,
      fromJson: User.fromJson,
    );

    if (response.isSuccess && response.data != null) {
      return response.data!;
    } else {
      throw Exception('Failed to update profile fields: ${response.error}');
    }
  }

  // Upload profile picture with improved error handling
  Future<bool> uploadProfilePicture(File imageFile) async {
    try {
      // Create a multipart request
      final uri = Uri.parse(
        '${AppConfig.baseUrl}${ApiEndpoints.profilePicture}',
      );
      final request = http.MultipartRequest('POST', uri);

      // Add JWT authorization
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }
      request.headers['Authorization'] = token;

      // Determine mime type
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final fileType = mimeType.split('/');

      // Add the file
      final fileBytes = await imageFile.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'profile_picture',
        fileBytes,
        filename: imageFile.path.split('/').last,
        contentType: MediaType(fileType[0], fileType[1]),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Just check if successful, don't try to parse User object
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to upload profile picture: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading profile picture: $e');
    }
  }

  // Delete profile picture
  Future<bool> deleteProfilePicture() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _apiService.delete(
      ApiEndpoints.profilePicture,
      headers: {'Authorization': token},
    );

    return response.isSuccess;
  }

  // Upload CV with improved error handling
  Future<bool> uploadCV(File cvFile) async {
    try {
      // Create a multipart request
      final uri = Uri.parse('${AppConfig.baseUrl}${ApiEndpoints.cv}');
      final request = http.MultipartRequest('POST', uri);

      // Add JWT authorization
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Authorization token is missing');
      }
      request.headers['Authorization'] = token;

      // Determine mime type
      final mimeType = lookupMimeType(cvFile.path) ?? 'application/pdf';
      final fileType = mimeType.split('/');

      // Add the file
      final fileBytes = await cvFile.readAsBytes();

      final multipartFile = http.MultipartFile.fromBytes(
        'cv',
        fileBytes,
        filename: cvFile.path.split('/').last,
        contentType: MediaType(fileType[0], fileType[1]),
      );

      request.files.add(multipartFile);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      // Just check if successful, don't try to parse User object
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to upload CV: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading CV: $e');
    }
  }

  // Delete CV
  Future<bool> deleteCV() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final response = await _apiService.delete(
      ApiEndpoints.cv,
      headers: {'Authorization': token},
    );

    return response.isSuccess;
  }
}
