import 'package:flutter/material.dart';

/// Base error class for all application errors
abstract class AppError {
  const AppError({
    required this.userMessage,
    required this.severity,
    this.technicalDetails,
    this.recoveryActions = const [],
  });

  /// User-friendly message to display
  final String userMessage;

  /// Error severity level
  final ErrorSeverity severity;

  /// Technical details for debugging (not shown to user)
  final String? technicalDetails;

  /// Possible recovery actions the user can take
  final List<RecoveryAction> recoveryActions;
}

/// Error severity levels
enum ErrorSeverity {
  info, // Informational messages
  warning, // Non-critical issues
  error, // Error states that need attention
  critical, // Critical issues requiring immediate action
}

/// Represents an action the user can take to recover from an error
class RecoveryAction {
  const RecoveryAction({
    required this.label,
    required this.action,
    this.icon,
    this.isPrimary = false,
  });

  /// Button label
  final String label;

  /// Action to execute when tapped
  final VoidCallback action;

  /// Optional icon to display
  final IconData? icon;

  /// Whether this is the primary/recommended action
  final bool isPrimary;
}

/// Validation error for form fields
class ValidationError extends AppError {
  const ValidationError(String message, {super.recoveryActions})
    : super(userMessage: message, severity: ErrorSeverity.warning);
}

/// Network connectivity error
class NetworkError extends AppError {
  const NetworkError({String? details, super.recoveryActions})
    : super(
        userMessage:
            "Connection problem. Please check your internet and try again.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Server response timeout error (server is slow or overloaded)
class ServerSlowError extends AppError {
  const ServerSlowError({String? details, super.recoveryActions})
    : super(
        userMessage:
            "The server is taking longer than expected. Please try again.",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );
}

/// Authentication/authorization error
class AuthenticationError extends AppError {
  const AuthenticationError({String? details})
    : super(
        userMessage:
            "We couldn't verify your information. Please check your details.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Sign-in specific error (incorrect credentials)
class SignInError extends AppError {
  const SignInError({String? details})
    : super(
        userMessage:
            "Incorrect email or password. Do you have an account? \n*Note: A new account for this year is required.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Email already exists error (signup flow)
class EmailExistsError extends AppError {
  const EmailExistsError(this.email, {super.recoveryActions})
    : super(
        userMessage: "An account with this email already exists.",
        severity: ErrorSeverity.warning,
      );

  final String email;
}

/// Rate limiting error
class RateLimitError extends AppError {
  const RateLimitError(this.waitTime, {super.recoveryActions})
    : super(
        userMessage: "Too many attempts. Please wait before trying again.",
        severity: ErrorSeverity.warning,
      );

  final Duration waitTime;
}

/// Profile loading failed error
class ProfileLoadingError extends AppError {
  const ProfileLoadingError({String? details})
    : super(
        userMessage:
            "We're having trouble loading your profile. Please sign in again.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Server error (5xx responses)
class ServerError extends AppError {
  const ServerError({String? details})
    : super(
        userMessage: "Something went wrong on our end. Please try again later.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Unknown/unexpected error
class UnknownError extends AppError {
  const UnknownError(String details, {super.recoveryActions})
    : super(
        userMessage: "Something unexpected happened. Please try again.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Invalid verification code error
class VerificationCodeError extends AppError {
  const VerificationCodeError({String? details, super.recoveryActions})
    : super(
        userMessage:
            "The verification code is incorrect. Please check your email and try again.",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );
}

/// Signup validation error (email format, password strength)
class SignupValidationError extends AppError {
  const SignupValidationError(
    String message, {
    String? details,
    super.recoveryActions,
  }) : super(
         userMessage: message,
         severity: ErrorSeverity.warning,
         technicalDetails: details,
       );
}

/// Password reset error (invalid email, not found)
class PasswordResetError extends AppError {
  const PasswordResetError({String? details, super.recoveryActions})
    : super(
        userMessage:
            "We couldn't send a reset email. Please check your email address and try again.",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );
}

/// Rate limiting for auth operations
class AuthRateLimitError extends AppError {
  const AuthRateLimitError(
    String message, {
    required this.waitTime,
    super.recoveryActions,
  }) : super(userMessage: message, severity: ErrorSeverity.warning);

  final Duration waitTime;
}

/// Invalid email format during auth
class EmailFormatError extends AppError {
  const EmailFormatError({String? details, super.recoveryActions})
    : super(
        userMessage: "Please enter a valid email address.",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );
}
