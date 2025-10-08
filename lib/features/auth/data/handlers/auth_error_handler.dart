import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/exception.dart';

/// Auth-specific error handler with appropriate logging levels for expected vs unexpected errors
class AuthErrorHandler {
  /// Handle DioException with auth-specific logging and error mapping
  static Future<Exception> handleDioException(
    DioException dioException, {
    required String operation,
    Map<String, dynamic>? additionalContext,
  }) async {
    final statusCode = dioException.response?.statusCode;
    final responseBody = _extractResponseBody(dioException.response);

    // Debug logging (only in debug mode)
    if (kDebugMode) {
      print('=== Auth Error Details ===');
      print('Operation: $operation');
      print('Method: ${dioException.requestOptions.method}');
      print('URL: ${dioException.requestOptions.uri}');
      print('Status Code: $statusCode');
      print('Response Body: $responseBody');
      print('========================');
    }

    // Determine if this is an expected auth error
    final isExpectedError = _isExpectedAuthError(statusCode, operation);

    if (isExpectedError) {
      // Log as warning for expected business logic errors
      _logExpectedError(
        operation: operation,
        statusCode: statusCode,
        responseBody: responseBody,
        additionalContext: additionalContext,
      );
    } else {
      // Capture to Sentry for unexpected errors
      await _logUnexpectedError(
        dioException: dioException,
        operation: operation,
        statusCode: statusCode,
        additionalContext: additionalContext,
      );
    }

    // Map to appropriate exception type
    return _mapStatusCodeToException(
      statusCode,
      responseBody,
      dioException,
      operation,
    );
  }

  /// Check if status code represents an expected auth error
  static bool _isExpectedAuthError(int? statusCode, String operation) {
    return statusCode == 401 || // Incorrect credentials
        statusCode == 400 || // Validation errors
        statusCode == 429 || // Rate limiting (beginSignup, resetPassword)
        (statusCode == 406 &&
            operation ==
                'beginSignup') || // Password validation failed (beginSignup)
        (statusCode == 409 &&
            operation == 'beginSignup') || // Email exists (beginSignup)
        (statusCode == 415 &&
            operation == 'beginSignup'); // Invalid schema (beginSignup)
  }

  /// Log expected errors with structured attributes
  static void _logExpectedError({
    required String operation,
    int? statusCode,
    String? responseBody,
    Map<String, dynamic>? additionalContext,
  }) {
    final attributes = <String, SentryLogAttribute>{
      'operation': SentryLogAttribute.string(operation),
      'status_code': SentryLogAttribute.string(
        statusCode?.toString() ?? 'unknown',
      ),
      'error_category': SentryLogAttribute.string('expected_auth_error'),
      'severity': SentryLogAttribute.string('expected'),
    };

    if (additionalContext != null) {
      for (final entry in additionalContext.entries) {
        attributes[entry.key] = SentryLogAttribute.string(
          entry.value.toString(),
        );
      }
    }

    Sentry.logger.info(
      _getExpectedErrorMessage(statusCode, operation),
      attributes: attributes,
    );
  }

  /// Capture unexpected errors to Sentry with full context
  static Future<void> _logUnexpectedError({
    required DioException dioException,
    required String operation,
    int? statusCode,
    Map<String, dynamic>? additionalContext,
  }) async {
    await Sentry.captureException(
      dioException,
      withScope: (scope) {
        scope.setTag('error_type', 'auth_error');
        scope.setTag('operation', operation);
        scope.setTag('status_code', statusCode?.toString() ?? 'unknown');
        if (additionalContext != null) {
          scope.setTag('additional_context', additionalContext.toString());
        }
      },
    );
  }

  /// Extract response body as string
  static String? _extractResponseBody(Response? response) {
    if (response?.data == null) return null;

    if (response!.data is String) {
      return response.data as String;
    } else if (response.data is Map<String, dynamic>) {
      // Try common error message fields
      final data = response.data as Map<String, dynamic>;
      for (final key in ['message', 'error', 'detail', 'description']) {
        if (data.containsKey(key) && data[key] is String) {
          return data[key] as String;
        }
      }
      return data.toString();
    }

    return response.data.toString();
  }

  /// Map status code to appropriate exception with user-friendly messages
  static Exception _mapStatusCodeToException(
    int? statusCode,
    String? responseBody,
    DioException originalException,
    String operation,
  ) {
    switch (statusCode) {
      case 400:
        return ValidationException(
          responseBody ?? 'Please check your input and try again',
        );
      case 401:
        // Specific message for incorrect credentials
        return const AuthException('Incorrect email or password');
      case 403:
        return const AuthException(
          'Access denied. Please check your credentials',
        );
      case 404:
        // Context-specific 404 messages handled in data source
        return ValidationException(
          responseBody ?? 'The requested resource was not found',
        );
      case 406:
        // For beginSignup: 406 means password validation failed (per API spec)
        if (operation == 'beginSignup') {
          return ApiException(
            responseBody ?? 'Password does not meet requirements',
            406,
          );
        }
        // For other operations: generic not acceptable error
        return ValidationException(responseBody ?? 'Request not acceptable');
      case 409:
        // For beginSignup: 409 means email already exists (per API spec)
        if (operation == 'beginSignup') {
          return ApiException(
            responseBody ?? 'An account with this email already exists',
            409,
          );
        }
        // For other operations: generic conflict error
        return ValidationException(responseBody ?? 'This item already exists');
      case 415:
        // For beginSignup: 415 means invalid signup schema (per API spec)
        if (operation == 'beginSignup') {
          return ValidationException(
            responseBody ?? 'Please check your signup information',
          );
        }
        // For other operations: generic unsupported media type
        return ValidationException(
          responseBody ?? 'Please check your input format',
        );
      case 429:
        // Rate limiting
        return const ApiException(
          'Too many requests. Please wait a moment before trying again',
          429,
        );
      case 500:
      case 502:
      case 503:
      case 504:
        return const NetworkException('Server error. Please try again later');
      default:
        if (statusCode != null && statusCode >= 400) {
          return ApiException(
            responseBody ?? 'Something went wrong. Please try again',
            statusCode,
          );
        }
        // Network-level errors (no response)
        return const NetworkException(
          'Unable to connect. Please check your internet connection',
        );
    }
  }

  /// Get appropriate message for expected errors
  static String _getExpectedErrorMessage(int? statusCode, String operation) {
    switch (statusCode) {
      case 401:
        return 'Auth $operation - invalid credentials (expected)';
      case 404:
        return 'Auth $operation - resource not found (expected)';
      case 400:
        return 'Auth $operation - validation error (expected)';
      case 406:
        if (operation == 'beginSignup') {
          return 'Auth $operation - password validation failed (expected)';
        }
        return 'Auth $operation - not acceptable (expected)';
      case 409:
        if (operation == 'beginSignup') {
          return 'Auth $operation - email already exists (expected)';
        }
        return 'Auth $operation - resource conflict (expected)';
      case 415:
        if (operation == 'beginSignup') {
          return 'Auth $operation - invalid signup schema (expected)';
        }
        return 'Auth $operation - unsupported media type (expected)';
      default:
        return 'Auth $operation - status $statusCode (expected)';
    }
  }
}
