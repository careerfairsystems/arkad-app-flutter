import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import '../config/app_config.dart';

class UserService {
  final AuthService _authService;

  UserService({AuthService? authService})
      : _authService = authService ?? AuthService();

  // Get user profile
  Future<User> getUserProfile() async {
    final response = await _authService.authenticatedRequest(
      'GET',
      '/user/profile',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to get user profile: ${response.body}');
    }
  }

  // Update complete profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    final response = await _authService.authenticatedRequest(
      'PUT',
      '/user/profile',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(profileData),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // Update individual profile fields
  Future<User> updateProfileFields(Map<String, dynamic> fields) async {
    final response = await _authService.authenticatedRequest(
      'PATCH',
      '/user/profile',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(fields),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to update profile fields: ${response.body}');
    }
  }

  // Upload profile picture with improved error handling
  Future<User> uploadProfilePicture(File imageFile) async {
    try {
      // Create a multipart request
      final uri =
          Uri.parse('${AppConfig.baseUrl}/user/profile/profile-picture');
      final request = http.MultipartRequest('POST', uri);

      // Add JWT authorization
      final token = await _authService.getValidToken();
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

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return User.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to upload profile picture: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading profile picture: $e');
    }
  }

  // Delete profile picture
  Future<User> deleteProfilePicture() async {
    final response = await _authService.authenticatedRequest(
      'DELETE',
      '/user/profile/profile-picture',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to delete profile picture: ${response.body}');
    }
  }

  // Upload CV with improved error handling
  Future<User> uploadCV(File cvFile) async {
    try {
      // Create a multipart request
      final uri = Uri.parse('${AppConfig.baseUrl}/user/profile/cv');
      final request = http.MultipartRequest('POST', uri);

      // Add JWT authorization
      final token = await _authService.getValidToken();
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

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return User.fromJson(jsonResponse);
      } else {
        throw Exception('Failed to upload CV: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading CV: $e');
    }
  }

  // Delete CV
  Future<User> deleteCV() async {
    final response = await _authService.authenticatedRequest(
      'DELETE',
      '/user/profile/cv',
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return User.fromJson(jsonResponse);
    } else {
      throw Exception('Failed to delete CV: ${response.body}');
    }
  }
}
