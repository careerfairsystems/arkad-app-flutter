import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_error.dart';

/// Maps HTTP errors and exceptions to user-friendly AppErrors
class ErrorMapper {
  /// Maps a DioException to an appropriate AppError with context
  static AppError fromDioException(DioException exception, BuildContext? context, {String? operationContext}) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;
    
    switch (statusCode) {
      case 400:
        return ValidationError(_extractErrorMessage(responseData) ?? 
            "Please check your information and try again.");
            
      case 401:
        // Context-aware 401 handling
        if (operationContext == 'signin') {
          return SignInError(details: exception.toString());
        } else {
          return ProfileLoadingError(details: exception.toString());
        }
        
      case 415:
        // Email already exists during signup
        final email = _extractEmailFromRequest(exception.requestOptions.data);
        if (email != null) {
          return EmailExistsError(email);
        }
        return ValidationError("An account with this email already exists.");
        
      case 425:
        // Rate limiting
        final waitTime = _extractWaitTime(responseData) ?? const Duration(minutes: 2);
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
            action: () => Navigator.of(context).pop(),
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
      return responseData['message'] ?? responseData['detail'] ?? responseData['error'];
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
}