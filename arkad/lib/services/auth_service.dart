import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service responsible for authentication operations
class AuthService {
  // API Constants
  static String get _baseUrl => AppConfig.baseUrl;
  static const String _beginSignupEndpoint = '/user/begin-signup';
  static const String _completeSignupEndpoint = '/user/complete-signup';
  static const String _signinEndpoint = '/user/signin';

  // Storage Keys
  static const String _tokenKey = 'auth_token';
  static const String _tokenExpiryKey = 'auth_token_expiry';
  static const String _emailKey = 'temp_email';
  static const String _passwordKey = 'temp_password';

  // Default HTTP headers
  static final Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'accept': 'application/json',
  };

  final FlutterSecureStorage _storage;

  /// Creates an instance of AuthService with optional storage dependency
  AuthService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Begins the signup process
  ///
  /// Sends email and password to the backend and stores credentials temporarily
  /// for the complete-signup step
  Future<void> beginSignup(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_beginSignupEndpoint'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _validateResponse(response,
          successMessage: 'Signup initiated successfully',
          errorMessage: 'Failed to initiate signup');

      // Extract token directly from the response body
      final token = jsonDecode(response.body);

      if (token == null) {
        throw AuthException('Failed to extract token');
      }
      // Store auth token and credentials for verification step
      await _storeAuthData(token, email, password);
    } catch (e) {
      throw AuthException('Failed to initiate signup: ${e.toString()}');
    }
  }

  /// Completes the signup process with verification code
  Future<void> completeSignup(String code) async {
    try {
      final token = await _storage.read(key: _tokenKey);
      final email = await _storage.read(key: _emailKey);
      final password = await _storage.read(key: _passwordKey);

      if (token == null || email == null || password == null) {
        throw AuthException('Missing authentication data');
      }

      final response = await http.post(
        Uri.parse('$_baseUrl$_completeSignupEndpoint'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'token': token,
          'code': code,
          'email': email,
          'password': password,
        }),
      );

      _validateResponse(response,
          successMessage: 'Signup verified successfully',
          errorMessage: 'Failed to verify signup');

      // No need to store anything here - we'll signin next
    } catch (e) {
      throw AuthException('Verification failed: ${e.toString()}');
    }
  }

  /// Signs in a user with email and password
  ///
  /// Returns the authentication token
  Future<String> signin(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_signinEndpoint'),
        headers: _defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      _validateResponse(response,
          successMessage: 'Signed in successfully',
          errorMessage: 'Authentication failed');

      final token = jsonDecode(response.body);

      // Calculate expiry (24 hours from now)
      final expiryTime =
          DateTime.now().add(const Duration(hours: 24)).toIso8601String();

      // Store the token and expiry
      await _storage.write(key: _tokenKey, value: token);
      await _storage.write(key: _tokenExpiryKey, value: expiryTime);

      // Clear temporary credentials (cleanup)
      await _clearTemporaryData();

      return token;
    } catch (e) {
      throw AuthException('Authentication failed: ${e.toString()}');
    }
  }

  /// Gets a valid token, refreshing if necessary
  Future<String?> getValidToken() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;

    if (await _isTokenExpired()) {
      // Token expired, needs refresh
      return null; // Currently no refresh mechanism
    }

    return token;
  }

  /// Checks if the stored token is expired
  Future<bool> _isTokenExpired() async {
    final expiryString = await _storage.read(key: _tokenExpiryKey);
    if (expiryString == null) return true;

    try {
      final expiry = DateTime.parse(expiryString);
      return DateTime.now().isAfter(expiry);
    } catch (_) {
      return true;
    }
  }

  /// Makes an authenticated request to the API
  Future<http.Response> authenticatedRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await getValidToken();
    if (token == null) {
      throw AuthException('Not authenticated');
    }

    final allHeaders = {
      'Authorization': token,
      ..._defaultHeaders,
      ...?headers,
    };

    final uri = Uri.parse('$_baseUrl$endpoint');

    try {
      switch (method.toUpperCase()) {
        case 'GET':
          return await http.get(uri, headers: allHeaders);
        case 'POST':
          return await http.post(uri, headers: allHeaders, body: body);
        case 'PUT':
          return await http.put(uri, headers: allHeaders, body: body);
        case 'PATCH':
          return await http.patch(uri, headers: allHeaders, body: body);
        case 'DELETE':
          return await http.delete(uri, headers: allHeaders);
        default:
          throw ArgumentError('Unsupported HTTP method: $method');
      }
    } catch (e) {
      throw AuthException('API request failed: ${e.toString()}');
    }
  }

  /// Validates HTTP response and throws appropriate exceptions
  void _validateResponse(http.Response response,
      {required String successMessage, required String errorMessage}) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException('$errorMessage: ${response.body}');
    }
  }

  /// Stores authentication data in secure storage
  Future<void> _storeAuthData(
      String token, String email, String password) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _emailKey, value: email);
    await _storage.write(key: _passwordKey, value: password);
  }

  /// Clears temporary authentication data
  Future<void> _clearTemporaryData() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _passwordKey);
  }

  /// Retrieves stored email
  Future<String?> getStoredEmail() async {
    return await _storage.read(key: _emailKey);
  }

  /// Retrieves stored password
  Future<String?> getStoredPassword() async {
    return await _storage.read(key: _passwordKey);
  }

  /// Completely logs out the user and clears all stored data
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _clearTemporaryData();
  }
}

/// Custom exception class for authentication errors
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
