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
        // Note: setExtra is deprecated but setContext isn't available in this version
        // We'll use tags for now since they're supported
        scope.setTag('operation', operationName ?? 'unknown');
        if (additionalContext?.isNotEmpty == true) {
          scope.setTag('additional_context', additionalContext.toString());
        }
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
  static Exception _mapStatusCodeToException(
    int? statusCode,
    String? responseBody,
    DioException originalException,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          responseBody ?? 'Please check your input and try again',
        );
      case 401:
        return AuthException(
          responseBody ?? 'Please sign in to continue',
        );
      case 403:
        return AuthException(
          responseBody ?? 'You don\'t have permission to perform this action',
        );
      case 404:
        return ApiException(
          'The requested item could not be found',
        );
      case 409:
        return ValidationException(
          responseBody ?? 'This item already exists',
        );
      case 415:
        return ValidationException(
          responseBody ?? 'Please check your input format',
        );
      case 429:
        return ApiException(
          responseBody ?? 'Please wait a moment before trying again',
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return NetworkException(
          'Something went wrong. Please try again later',
        );
      default:
        if (statusCode != null && statusCode >= 400) {
          return ApiException(
            responseBody ?? 'Something went wrong. Please try again',
          );
        }
        // Network-level errors (no response)
        return NetworkException(
          'Please check your internet connection',
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
}
