import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_error.dart';
import 'student_session_errors.dart';

/// Maps HTTP errors and exceptions to user-friendly AppErrors
class ErrorMapper {
  /// Maps a DioException to an appropriate AppError with context
  static AppError fromDioException(
    DioException exception,
    BuildContext? context, {
    String? operationContext,
  }) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;

    switch (statusCode) {
      case 400:
        // Student session specific 400 errors
        if (operationContext?.contains('student_session') == true) {
          final errorMessage = _extractErrorMessage(responseData);
          if (errorMessage?.contains('timeline') == true ||
              errorMessage?.contains('application period') == true) {
            return const StudentSessionTimelineError(
              message:
                  'You can only apply during the application period (Oct 13-26, 2025).',
            );
          }
          if (errorMessage?.contains('invalid') == true ||
              errorMessage?.contains('validation') == true) {
            return StudentSessionApplicationError(
              errorMessage ?? 'Invalid application data.',
            );
          }
        }
        return ValidationError(
          _extractErrorMessage(responseData) ??
              "Please check your information and try again.",
        );

      case 401:
        // Context-aware 401 handling
        if (operationContext == 'signin') {
          return SignInError(details: exception.toString());
        } else {
          return ProfileLoadingError(details: exception.toString());
        }

      case 403:
        // Student session access denied
        if (operationContext?.contains('student_session') == true) {
          return const StudentSessionApplicationError(
            'You do not have permission to perform this action.',
          );
        }
        return const ValidationError('Access denied.');

      case 409:
        // Student session conflicts
        if (operationContext?.contains('student_session') == true) {
          final errorMessage = _extractErrorMessage(responseData);
          if (errorMessage?.contains('already applied') == true) {
            return const StudentSessionAlreadyAppliedError('this company');
          }
          if (errorMessage?.contains('booking') == true ||
              errorMessage?.contains('conflict') == true) {
            return const StudentSessionBookingConflictError(
              'This timeslot was just booked by someone else.',
            );
          }
          if (errorMessage?.contains('capacity') == true ||
              errorMessage?.contains('full') == true) {
            return const StudentSessionCapacityError('this company');
          }
        }
        return ValidationError(
          _extractErrorMessage(responseData) ?? 'Conflict occurred.',
        );

      case 413:
        // File size error
        if (operationContext?.contains('student_session') == true ||
            operationContext?.contains('upload') == true) {
          return const StudentSessionFileUploadError(
            'file',
            details: 'File is too large. Maximum size is 10MB.',
          );
        }
        return const ValidationError('File is too large.');

      case 415:
        // Email already exists during signup
        final email = _extractEmailFromRequest(exception.requestOptions.data);
        if (email != null) {
          return EmailExistsError(email);
        }
        return ValidationError("An account with this email already exists.");

      case 429:
        // Rate limiting
        final waitTime =
            _extractWaitTime(responseData) ?? const Duration(minutes: 2);
        return RateLimitError(waitTime);

      case 500:
      case 502:
      case 503:
      case 504:
        return const ServerError();

      default:
        if (exception.type == DioExceptionType.connectionTimeout ||
            exception.type == DioExceptionType.receiveTimeout ||
            exception.type == DioExceptionType.sendTimeout) {
          return const NetworkError();
        }

        if (exception.type == DioExceptionType.connectionError) {
          return const NetworkError();
        }

        return UnknownError(exception.toString());
    }
  }

  /// Maps any exception to a safe, user-friendly AppError
  /// This method handles non-Dio exceptions and provides generic error messages
  /// without exposing internal exception details to users
  static AppError fromException(
    dynamic exception,
    BuildContext? context, {
    String? operationContext,
  }) {
    // If it's a DioException, use the specialized mapper
    if (exception is DioException) {
      return fromDioException(
        exception,
        context,
        operationContext: operationContext,
      );
    }

    // For all other exceptions, return a generic user-friendly error
    // Log the actual exception for debugging but don't expose it to users
    if (kDebugMode) {
      debugPrint('Exception in $operationContext: $exception');
    }

    return const UnknownError('An unexpected error occurred');
  }

  /// Creates recovery actions based on error type and context
  static List<RecoveryAction> createRecoveryActions(
    AppError error,
    BuildContext? context,
    VoidCallback? onRetry,
  ) {
    if (context == null) return [];

    switch (error.runtimeType) {
      case EmailExistsError _:
        final emailError = error as EmailExistsError;
        return [
          RecoveryAction(
            label: "Sign In Instead",
            action: () => _navigateToLogin(context, emailError.email),
            isPrimary: true,
            icon: Icons.login,
          ),
          RecoveryAction(
            label: "Reset Password",
            action: () => _navigateToPasswordReset(context, emailError.email),
            icon: Icons.lock_reset,
          ),
          RecoveryAction(
            label: "Use Different Email",
            action: () => context.pop(),
            icon: Icons.edit,
          ),
        ];

      case RateLimitError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Contact Support",
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        ];

      case ProfileLoadingError _:
        return [
          RecoveryAction(
            label: "Sign In Again",
            action: () => _signInAgain(context),
            isPrimary: true,
            icon: Icons.refresh,
          ),
          RecoveryAction(
            label: "Contact Support",
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        ];

      case NetworkError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Check Connection",
            action: () => _showNetworkSettings(context),
            icon: Icons.settings,
          ),
        ];

      case AuthenticationError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Reset Password",
            action: () => _navigateToPasswordReset(context, null),
            icon: Icons.lock_reset,
          ),
        ];

      case SignInError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Reset Password",
            action: () => _navigateToPasswordReset(context, null),
            icon: Icons.lock_reset,
          ),
          RecoveryAction(
            label: "Create Account",
            action: () => context.push('/auth/signup'),
            icon: Icons.person_add,
          ),
        ];

      case ValidationError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Contact Support",
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        ];

      case StudentSessionTimelineError _:
        return [
          RecoveryAction(
            label: "Check Timeline",
            action: () => _showTimelineInfo(context),
            isPrimary: true,
            icon: Icons.schedule,
          ),
          RecoveryAction(
            label: "View Companies",
            action: () => context.go('/companies'),
            icon: Icons.business,
          ),
        ];

      case StudentSessionApplicationError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "View Profile",
            action: () => context.go('/profile'),
            icon: Icons.person,
          ),
        ];

      case StudentSessionAlreadyAppliedError _:
        return [
          RecoveryAction(
            label: "View My Applications",
            action: () => context.go('/profile'),
            isPrimary: true,
            icon: Icons.assignment,
          ),
          RecoveryAction(
            label: "Browse Other Companies",
            action: () => context.go('/companies'),
            icon: Icons.business,
          ),
        ];

      case StudentSessionBookingConflictError _:
        return [
          RecoveryAction(
            label: "Choose Different Time",
            action: () => context.pop(),
            isPrimary: true,
            icon: Icons.schedule,
          ),
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              icon: Icons.refresh,
            ),
        ];

      case StudentSessionCapacityError _:
        return [
          RecoveryAction(
            label: "Browse Other Companies",
            action: () => context.go('/companies'),
            isPrimary: true,
            icon: Icons.business,
          ),
          RecoveryAction(
            label: "Check Back Later",
            action: () => context.pop(),
            icon: Icons.schedule,
          ),
        ];

      case StudentSessionFileUploadError _:
        return [
          RecoveryAction(
            label: "Choose Different File",
            action: () => context.pop(),
            isPrimary: true,
            icon: Icons.file_upload,
          ),
          RecoveryAction(
            label: "Compress File",
            action: () => _showFileCompressionHelp(context),
            icon: Icons.compress,
          ),
        ];

      case UnknownError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Contact Support",
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        ];

      default:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Contact Support",
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        ];
    }
  }

  // Helper methods
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is String) return responseData;
    if (responseData is Map<String, dynamic>) {
      return responseData['message'] ??
          responseData['detail'] ??
          responseData['error'];
    }
    return null;
  }

  static String? _extractEmailFromRequest(dynamic requestData) {
    if (requestData is Map<String, dynamic>) {
      return requestData['email'] as String?;
    }
    return null;
  }

  static Duration? _extractWaitTime(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      final seconds = responseData['retry_after'] as int?;
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return null;
  }

  // Navigation helpers
  static void _navigateToLogin(BuildContext context, String? email) {
    context.go('/auth/login', extra: {'email': email});
  }

  static void _navigateToPasswordReset(BuildContext context, String? email) {
    context.push('/auth/reset-password', extra: {'email': email});
  }

  static void _signInAgain(BuildContext context) {
    context.go('/auth/login');
  }

  static void _contactSupport(BuildContext context) {
    // TODO: Implement support contact
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support at support@arkadtlth.se')),
    );
  }

  static void _showNetworkSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please check your internet connection')),
    );
  }

  static void _showTimelineInfo(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Application period: Oct 13-26, 2025, Booking period: Nov 2 17:00 - Nov 5 23:59, 2025',
        ),
        duration: Duration(seconds: 5),
      ),
    );
  }

  static void _showFileCompressionHelp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please compress your file to under 10MB or use a different format.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
