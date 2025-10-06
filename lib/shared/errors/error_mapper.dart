import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/event/data/data_sources/event_remote_data_source.dart';
import 'app_error.dart';
import 'event_errors.dart';
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
        // Auth-specific 400 errors
        if (operationContext == 'signup') {
          final errorMessage = _extractErrorMessage(responseData);
          if (errorMessage?.toLowerCase().contains('email') == true) {
            return EmailFormatError(details: errorMessage);
          }
          if (errorMessage?.toLowerCase().contains('password') == true) {
            return SignupValidationError(
              errorMessage ?? 'Password requirements not met',
              details: errorMessage,
            );
          }
          return SignupValidationError(
            errorMessage ?? 'Please check your signup information',
            details: errorMessage,
          );
        }

        if (operationContext == 'verification') {
          final errorMessage = _extractErrorMessage(responseData);
          return VerificationCodeError(details: errorMessage);
        }

        if (operationContext == 'password_reset') {
          final errorMessage = _extractErrorMessage(responseData);
          return PasswordResetError(details: errorMessage);
        }

        // Student session specific 400 errors
        if (operationContext?.contains('student_session') == true) {
          final errorMessage = _extractErrorMessage(responseData);
          // Timeline errors now handled as generic application errors
          // Session availability controlled by server data (available field, userStatus)
          if (errorMessage?.contains('timeline') == true ||
              errorMessage?.contains('application period') == true) {
            return StudentSessionApplicationError(
              errorMessage ?? 'Application not available at this time.',
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
        return const ValidationError(
          "An account with this email already exists.",
        );

      case 429:
        // Rate limiting with auth-specific messages
        final waitTime =
            _extractWaitTime(responseData) ?? const Duration(seconds: 30);
        final waitTimeText = _formatDuration(waitTime);

        if (operationContext == 'signup') {
          return AuthRateLimitError(
            'Please wait $waitTimeText before requesting another verification email.',
            waitTime: waitTime,
          );
        }
        if (operationContext == 'password_reset') {
          return AuthRateLimitError(
            'Please wait $waitTimeText before requesting another password reset.',
            waitTime: waitTime,
          );
        }

        // Generic rate limiting
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

    // Handle custom event exceptions
    if (exception is EventFullException) {
      return EventFullError('Event', details: exception.message);
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

      // Timeline error recovery removed - backend prevents invalid operations

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

      case VerificationCodeError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Resend Code",
              action: onRetry,
              isPrimary: true,
              icon: Icons.email,
            ),
          RecoveryAction(
            label: "Change Email",
            action: () => context.go('/auth/signup'),
            icon: Icons.edit,
          ),
        ];

      case SignupValidationError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Back to Login",
            action: () => context.go('/auth/login'),
            icon: Icons.arrow_back,
          ),
        ];

      case PasswordResetError _:
        return [
          if (onRetry != null)
            RecoveryAction(
              label: "Try Again",
              action: onRetry,
              isPrimary: true,
              icon: Icons.refresh,
            ),
          RecoveryAction(
            label: "Back to Login",
            action: () => context.go('/auth/login'),
            icon: Icons.arrow_back,
          ),
        ];

      case AuthRateLimitError _:
        final rateError = error as AuthRateLimitError;
        return [
          RecoveryAction(
            label: "Wait ${rateError.waitTime.inSeconds}s",
            action: () {}, // Disabled action
            icon: Icons.timer,
          ),
          RecoveryAction(
            label: "Back to Login",
            action: () => context.go('/auth/login'),
            icon: Icons.arrow_back,
          ),
        ];

      case EmailFormatError _:
        return [
          RecoveryAction(
            label: "Fix Email",
            action: () => context.pop(),
            isPrimary: true,
            icon: Icons.edit,
          ),
        ];

      case EventFullError _:
        return [
          RecoveryAction(
            label: "Browse Other Events",
            action: () => context.go('/events'),
            isPrimary: true,
            icon: Icons.event,
          ),
          RecoveryAction(
            label: "Go Back",
            action: () => context.pop(),
            icon: Icons.arrow_back,
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

  static String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;

    // Use minutes for durations >= 60 seconds
    if (totalSeconds >= 60) {
      final minutes = duration.inMinutes;
      return minutes == 1 ? '1 minute' : '$minutes minutes';
    }

    // Use seconds for durations < 60 seconds
    return totalSeconds == 1 ? '1 second' : '$totalSeconds seconds';
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
    //

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Contact support at support@arkadtlth.se')),
    );
  }

  static void _showNetworkSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please check your internet connection')),
    );
  }

  // Timeline info method removed - not needed in data-driven approach

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
