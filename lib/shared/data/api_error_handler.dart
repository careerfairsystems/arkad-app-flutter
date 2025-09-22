import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../errors/exception.dart';

/// Enhanced error handler for API responses with detailed logging and Sentry integration
class ApiErrorHandler {
  /// Handle DioException with detailed logging and error mapping
  static Future<Exception> handleDioException(
    DioException dioException, {
    String? operationName,
    Map<String, dynamic>? additionalContext,
  }) async {
    final requestOptions = dioException.requestOptions;
    final response = dioException.response;

    // Extract response body
    String? responseBody;
    if (response?.data != null) {
      if (response!.data is String) {
        responseBody = response.data as String;
      } else if (response.data is Map<String, dynamic>) {
        responseBody = response.data.toString();
      }
    }

    // Create detailed error context
    final errorContext = {
      'operation': operationName ?? 'API call',
      'method': requestOptions.method,
      'url': requestOptions.uri.toString(),
      'statusCode': response?.statusCode,
      'statusMessage': response?.statusMessage,
      'responseBody': responseBody,
      'requestHeaders': _sanitizeHeaders(requestOptions.headers),
      'responseHeaders': response?.headers.map,
      'dioErrorType': dioException.type.toString(),
      'dioErrorMessage': dioException.message,
      ...?additionalContext,
    };

    // Debug logging (only in debug mode)
    if (kDebugMode) {
      print('=== API Error Details ===');
      print('Operation: ${operationName ?? 'API call'}');
      print('Method: ${requestOptions.method}');
      print('URL: ${requestOptions.uri}');
      print('Status Code: ${response?.statusCode}');
      print('Status Message: ${response?.statusMessage}');
      if (responseBody != null) {
        print('Response Body: $responseBody');
      }
      print('Error Type: ${dioException.type}');
      print('Error Message: ${dioException.message}');
      print('========================');
    }

    // Log to Sentry with context
    await Sentry.captureException(
      dioException,
      withScope: (scope) {
        scope.setTag('error_type', 'api_error');
        scope.setTag('operation', operationName ?? 'unknown');
        scope.setTag(
          'status_code',
          response?.statusCode?.toString() ?? 'unknown',
        );
        scope.setExtra('api_error_details', errorContext);
      },
    );

    // Map specific status codes to appropriate exceptions
    final statusCode = response?.statusCode;
    return _mapStatusCodeToException(statusCode, responseBody, dioException);
  }

  /// Map HTTP status codes to appropriate exceptions
  static Exception _mapStatusCodeToException(
    int? statusCode,
    String? responseBody,
    DioException originalException,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          responseBody ?? 'Bad request - please check your input',
        );
      case 401:
        return AuthException(
          responseBody ?? 'Authentication required - please sign in again',
        );
      case 403:
        return AuthException(
          responseBody ?? 'Access denied - insufficient permissions',
        );
      case 404:
        return ApiException(responseBody ?? 'Resource not found');
      case 409:
        return ValidationException(
          responseBody ?? 'Resource already exists or conflict occurred',
        );
      case 415:
        return ValidationException(
          responseBody ?? 'Invalid data format or content type',
        );
      case 429:
        return ApiException(
          responseBody ?? 'Too many requests - please wait before trying again',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return NetworkException('Server error - please try again later');
      default:
        if (statusCode != null && statusCode >= 400) {
          return ApiException(
            responseBody ?? 'Request failed with status $statusCode',
          );
        }
        // Network-level errors (no response)
        return NetworkException(
          originalException.message ?? 'Network error occurred',
        );
    }
  }

  /// Extract error message from response body
  static String extractErrorMessage(dynamic responseData) {
    if (responseData == null) return 'Unknown error occurred';

    if (responseData is String) {
      return responseData;
    }

    if (responseData is Map<String, dynamic>) {
      // Try common error message fields
      for (final key in ['message', 'error', 'detail', 'description']) {
        if (responseData.containsKey(key) && responseData[key] is String) {
          return responseData[key] as String;
        }
      }

      // If no standard field found, convert to string
      return responseData.toString();
    }

    return responseData.toString();
  }

  /// Sanitize headers to remove sensitive information
  static Map<String, dynamic> _sanitizeHeaders(Map<String, dynamic> headers) {
    final sanitized = Map<String, dynamic>.from(headers);

    // Remove sensitive headers
    const sensitiveKeys = [
      'authorization',
      'Authorization',
      'cookie',
      'Cookie',
      'x-api-key',
      'X-API-Key',
    ];

    for (final key in sensitiveKeys) {
      if (sanitized.containsKey(key)) {
        sanitized[key] = '[REDACTED]';
      }
    }

    return sanitized;
  }
}
