import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int statusCode;

  ApiResponse({this.data, this.error, required this.statusCode});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isError => !isSuccess;
}

class ApiService {
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  // Default headers
  Map<String, String> get _defaultHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  // Build full URL from endpoint
  Uri _buildUrl(String endpoint) {
    String baseUrl = AppConfig.baseUrl;
    return Uri.parse('$baseUrl$endpoint');
  }

  // GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await _client.get(
        _buildUrl(endpoint),
        headers: {..._defaultHeaders, ...?headers},
      ).timeout(
          timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  // POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUrl(endpoint),
            headers: {..._defaultHeaders, ...?headers},
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(
              timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  // PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .put(
            _buildUrl(endpoint),
            headers: {..._defaultHeaders, ...?headers},
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(
              timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  // PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .patch(
            _buildUrl(endpoint),
            headers: {..._defaultHeaders, ...?headers},
            body: body is String ? body : jsonEncode(body),
          )
          .timeout(
              timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  // DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) async {
    try {
      final response = await _client
          .delete(
            _buildUrl(endpoint),
            headers: {..._defaultHeaders, ...?headers},
            body: body != null && body is! String ? jsonEncode(body) : body,
          )
          .timeout(
              timeout ?? Duration(seconds: AppConfig.connectionTimeoutSeconds));

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(
        error: 'Network error: $e',
        statusCode: 0,
      );
    }
  }

  // Process response helper
  ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    try {
      final statusCode = response.statusCode;

      if (statusCode < 200 || statusCode >= 300) {
        return ApiResponse(
          error: _parseErrorMessage(response),
          statusCode: statusCode,
        );
      }

      // Handle empty responses
      if (response.body.isEmpty) {
        return ApiResponse<T>(
          statusCode: statusCode,
        );
      }

      // Parse JSON response
      final jsonData = jsonDecode(response.body);

      // Convert to model if fromJson is provided
      if (fromJson != null && jsonData is Map<String, dynamic>) {
        final T model = fromJson(jsonData);
        return ApiResponse<T>(
          data: model,
          statusCode: statusCode,
        );
      }

      // Return raw data if no conversion needed
      return ApiResponse<T>(
        data: jsonData as T,
        statusCode: statusCode,
      );
    } catch (e) {
      return ApiResponse(
        error: 'Failed to process response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  // Extract error message from response
  String _parseErrorMessage(http.Response response) {
    try {
      final jsonData = jsonDecode(response.body);
      if (jsonData is Map<String, dynamic> && jsonData.containsKey('message')) {
        return jsonData['message'];
      } else {
        return response.body;
      }
    } catch (e) {
      return 'Error ${response.statusCode}: ${response.body}';
    }
  }

  // Close client when done
  void dispose() {
    _client.close();
  }
}
