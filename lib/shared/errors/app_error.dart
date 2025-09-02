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
  info,     // Informational messages
  warning,  // Non-critical issues
  error,    // Error states that need attention
  critical  // Critical issues requiring immediate action
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
  const ValidationError(String message) : super(
    userMessage: message,
    severity: ErrorSeverity.warning,
  );
}

/// Network connectivity error
class NetworkError extends AppError {
  const NetworkError({String? details}) : super(
    userMessage: "Connection problem. Please check your internet and try again.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}

/// Authentication/authorization error
class AuthenticationError extends AppError {
  const AuthenticationError({String? details}) : super(
    userMessage: "We couldn't verify your information. Please check your details.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}

/// Sign-in specific error (incorrect credentials)
class SignInError extends AppError {
  const SignInError({String? details}) : super(
    userMessage: "Incorrect email or password. Please check your credentials and try again.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}

/// Email already exists error (signup flow)
class EmailExistsError extends AppError {
  const EmailExistsError(this.email, {super.recoveryActions}) : super(
    userMessage: "An account with this email already exists.",
    severity: ErrorSeverity.warning,
  );
  
  final String email;
}

/// Rate limiting error
class RateLimitError extends AppError {
  const RateLimitError(this.waitTime, {super.recoveryActions}) : super(
    userMessage: "Too many attempts. Please wait before trying again.",
    severity: ErrorSeverity.warning,
  );
  
  final Duration waitTime;
}

/// Profile loading failed error
class ProfileLoadingError extends AppError {
  const ProfileLoadingError({String? details}) : super(
    userMessage: "We're having trouble loading your profile. Please sign in again.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}

/// Server error (5xx responses)
class ServerError extends AppError {
  const ServerError({String? details}) : super(
    userMessage: "Something went wrong on our end. Please try again later.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}

/// Unknown/unexpected error
class UnknownError extends AppError {
  const UnknownError(String details) : super(
    userMessage: "Something unexpected happened. Please try again.",
    severity: ErrorSeverity.error,
    technicalDetails: details,
  );
}