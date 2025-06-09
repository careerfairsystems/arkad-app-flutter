import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/api_endpoints.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class AuthService {
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'temp_email';
  static const String _passwordKey = 'temp_password';

  final FlutterSecureStorage _storage;
  final ApiService _apiService;

  AuthService({
    required FlutterSecureStorage storage,
    required ApiService apiService,
  }) : _storage = storage,
       _apiService = apiService;

  /// Starts signup by sending credentials and storing them temporarily.
  Future<void> beginSignup(
    String email,
    String password, {
    String? firstName,
    String? lastName,
    String? foodPreferences,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.beginSignup,
        body: {
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'foodPreferences': foodPreferences,
        },
      );

      if (response.isError) {
        throw AuthException('Signup initiation failed: ${response.error}');
      }

      final token = _parseTokenFromResponse(response);
      await _storeAuthData(token, email, password, firstName, lastName, foodPreferences);
    } catch (e) {
      throw AuthException('Signup initiation failed: ${e.toString()}');
    }
  }

  /// Completes signup by verifying the code.
  Future<void> completeSignup(String code) async {
    try {
      final authData = await _getStoredCredential();
      if (authData == null) {
        throw AuthException('Missing temporary authentication data');
      }

      final response = await _apiService.post(
        ApiEndpoints.completeSignup,
        body: {
          'token': authData.token,
          'code': code,
          'email': authData.email,
          'password': authData.password,
          'firstName': authData.firstName,
          'lastName': authData.lastName,
          'foodPreferences': authData.foodPreferences,
        },
      );

      if (response.isError) {
        throw AuthException('Signup verification failed: ${response.error}');
      }
    } catch (e) {
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  /// Signs in the user and stores token.
  Future<String> signin(String email, String password) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.signin,
        body: {'email': email, 'password': password},
      );

      if (response.isError) {
        throw AuthException('Signin failed: ${response.error}');
      }

      final token = _parseTokenFromResponse(response);
      await _storage.write(key: _tokenKey, value: token);
      await _clearTemporaryData();

      return token;
    } catch (e) {
      throw AuthException('Signin failed: ${e.toString()}');
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.resetPassword,
        body: {'email': email},
      );

      if (response.isError) {
        throw AuthException('Password reset failed: ${response.error}');
      }

      return true;
    } catch (e) {
      throw AuthException('Password reset failed: ${e.toString()}');
    }
  }

  /// Makes a raw HTTP call with Authorization header (fallback).
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw AuthException('Not authenticated');
    }

    final allHeaders = {'Authorization': token, ...?headers};

    final uri = Uri.parse('${AppConfig.baseUrl}$endpoint');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return http.get(uri, headers: allHeaders);
        case 'POST':
          return http.post(uri, headers: allHeaders, body: body);
        case 'PUT':
          return http.put(uri, headers: allHeaders, body: body);
        case 'PATCH':
          return http.patch(uri, headers: allHeaders, body: body);
        case 'DELETE':
          return http.delete(uri, headers: allHeaders);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw AuthException('API request failed: ${e.toString()}');
    }
  }

  /// Reads the stored authentication token.
  Future<String?> getToken() async => _storage.read(key: _tokenKey);

  /// Logs out the user and clears all stored data.
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _clearTemporaryData();
  }

  /// Retrieves stored email.
  Future<String?> getStoredEmail() async => _storage.read(key: _emailKey);

  /// Retrieves stored password.
  Future<String?> getStoredPassword() async => _storage.read(key: _passwordKey);

  // Private Helpers

  Future<void> _storeAuthData(
    String token,
    String email,
    String password,
    String? firstName,
    String? lastName,
    String? foodPreferences,
  ) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
    if (firstName != null) await _storage.write(key: 'firstName', value: firstName);
    if (lastName != null) await _storage.write(key: 'lastName', value: lastName);
    if (foodPreferences != null) await _storage.write(key: 'foodPreferences', value: foodPreferences);
  }

  Future<void> _clearTemporaryData() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  String _parseTokenFromResponse(ApiResponse response) {
    final token = response.data;
    if (token == null || token is! String) {
      throw AuthException('Missing or invalid token in response');
    }
    return token;
  }

  Future<_TempAuthData?> _getStoredCredential() async {
    final token = await _storage.read(key: _tokenKey);
    final email = await _storage.read(key: _emailKey);
    final password = await _storage.read(key: _passwordKey);
    final firstName = await _storage.read(key: 'firstName');
    final lastName = await _storage.read(key: 'lastName');
    final foodPreferences = await _storage.read(key: 'foodPreferences');
    if (token == null || email == null || password == null) return null;
    return _TempAuthData(token, email, password, firstName, lastName, foodPreferences);
  }
}

class _TempAuthData {
  final String token;
  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? foodPreferences;

  _TempAuthData(this.token, this.email, this.password, this.firstName, this.lastName, this.foodPreferences);
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
