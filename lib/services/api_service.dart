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

  ApiService({required http.Client client}) : _client = client;

  Map<String, String> get _defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Uri _buildUrl(String endpoint) => Uri.parse('${AppConfig.baseUrl}$endpoint');

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest<T>(
      method: 'GET',
      endpoint: endpoint,
      headers: headers,
      timeout: timeout,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest<T>(
      method: 'POST',
      endpoint: endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest<T>(
      method: 'PUT',
      endpoint: endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest<T>(
      method: 'PATCH',
      endpoint: endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
    T Function(Map<String, dynamic>)? fromJson,
    Duration? timeout,
  }) {
    return _sendRequest<T>(
      method: 'DELETE',
      endpoint: endpoint,
      headers: headers,
      body: body,
      timeout: timeout,
      fromJson: fromJson,
    );
  }

  Future<ApiResponse<T>> _sendRequest<T>({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
    Duration? timeout,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUrl(endpoint);
      final combinedHeaders = {..._defaultHeaders, ...?headers};
      final encodedBody =
          body != null && body is! String ? jsonEncode(body) : body;

      late http.Response response;

      switch (method.toUpperCase()) {
        case 'GET':
          response = await _client
              .get(uri, headers: combinedHeaders)
              .timeout(
                timeout ??
                    Duration(seconds: AppConfig.connectionTimeoutSeconds),
              );
        case 'POST':
          response = await _client
              .post(uri, headers: combinedHeaders, body: encodedBody)
              .timeout(
                timeout ??
                    Duration(seconds: AppConfig.connectionTimeoutSeconds),
              );
        case 'PUT':
          response = await _client
              .put(uri, headers: combinedHeaders, body: encodedBody)
              .timeout(
                timeout ??
                    Duration(seconds: AppConfig.connectionTimeoutSeconds),
              );
        case 'PATCH':
          response = await _client
              .patch(uri, headers: combinedHeaders, body: encodedBody)
              .timeout(
                timeout ??
                    Duration(seconds: AppConfig.connectionTimeoutSeconds),
              );
        case 'DELETE':
          response = await _client
              .delete(uri, headers: combinedHeaders, body: encodedBody)
              .timeout(
                timeout ??
                    Duration(seconds: AppConfig.connectionTimeoutSeconds),
              );
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      return _processResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse(error: 'Network error: $e', statusCode: 0);
    }
  }

  ApiResponse<T> _processResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final statusCode = response.statusCode;

    if (statusCode < 200 || statusCode >= 300) {
      return ApiResponse(
        error: _parseErrorMessage(response),
        statusCode: statusCode,
      );
    }

    if (response.body.isEmpty) {
      return ApiResponse<T>(statusCode: statusCode);
    }

    try {
      final jsonData = jsonDecode(response.body);
      if (fromJson != null && jsonData is Map<String, dynamic>) {
        return ApiResponse<T>(data: fromJson(jsonData), statusCode: statusCode);
      }
      return ApiResponse<T>(data: jsonData as T, statusCode: statusCode);
    } catch (e) {
      return ApiResponse(
        error: 'Failed to parse response: $e',
        statusCode: statusCode,
      );
    }
  }

  String _parseErrorMessage(http.Response response) {
    try {
      final jsonData = jsonDecode(response.body);
      return (jsonData is Map<String, dynamic> &&
              jsonData.containsKey('message'))
          ? jsonData['message']
          : response.body;
    } catch (_) {
      return 'Error ${response.statusCode}: ${response.body}';
    }
  }

  void dispose() {
    _client.close();
  }
}
