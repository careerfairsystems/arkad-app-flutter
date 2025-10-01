import 'package:flutter/material.dart';
import 'app_error.dart';

/// Student session application submission error
class StudentSessionApplicationError extends AppError {
  const StudentSessionApplicationError(String message, {String? details})
    : super(
        userMessage: message,
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

// Timeline validation error removed - session availability controlled by server data

/// Timeslot booking conflict error (race condition)
class StudentSessionBookingConflictError extends AppError {
  const StudentSessionBookingConflictError(this.conflictMessage)
    : super(
        userMessage:
            "Someone just booked this slot! Please choose another time.",
        severity: ErrorSeverity.warning,
      );

  final String conflictMessage;

  /// Get detailed conflict information for user feedback
  String get detailedMessage =>
      conflictMessage.isNotEmpty ? conflictMessage : userMessage;
}

/// Student session not found error
class StudentSessionNotFoundError extends AppError {
  const StudentSessionNotFoundError(this.companyName, {String? details})
    : super(
        userMessage: "Student session not found for $companyName",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );

  final String companyName;
}

/// Permission denied for student session operation
class StudentSessionPermissionError extends AppError {
  const StudentSessionPermissionError(String operation, {String? details})
    : super(
        userMessage: "You don't have permission to $operation",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// File upload error for student session CV/documents
class StudentSessionFileUploadError extends AppError {
  const StudentSessionFileUploadError(this.fileName, {String? details})
    : super(
        userMessage: "Failed to upload $fileName. Please try again.",
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );

  final String fileName;
}

/// Already applied error for duplicate applications
class StudentSessionAlreadyAppliedError extends AppError {
  const StudentSessionAlreadyAppliedError(this.companyName)
    : super(
        userMessage:
            "You have already applied to $companyName's student session",
        severity: ErrorSeverity.warning,
      );

  final String companyName;
}

/// Student session capacity full error
class StudentSessionCapacityError extends AppError {
  const StudentSessionCapacityError(this.companyName, {String? details})
    : super(
        userMessage: "Student session for $companyName is at full capacity",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );

  final String companyName;
}

// Timeline phases enum removed - status flow controlled by server data (userStatus, available fields)

/// Recovery actions for student session errors
class StudentSessionRecoveryActions {
  // Timeline error recovery removed - backend prevents invalid operations

  /// Create recovery actions for booking conflicts
  static List<RecoveryAction> forBookingConflict(
    StudentSessionBookingConflictError error,
    BuildContext? context,
    VoidCallback? onRefresh,
  ) {
    if (context == null) return [];

    return [
      if (onRefresh != null)
        RecoveryAction(
          label: 'Refresh Timeslots',
          action: onRefresh,
          icon: Icons.refresh,
          isPrimary: true,
        ),
      RecoveryAction(
        label: 'Choose Different Time',
        action: () => Navigator.of(context).pop(),
        icon: Icons.schedule,
      ),
    ];
  }

  /// Create recovery actions for application errors
  static List<RecoveryAction> forApplicationError(
    StudentSessionApplicationError error,
    BuildContext? context,
    VoidCallback? onRetry,
  ) {
    if (context == null) return [];

    return [
      if (onRetry != null)
        RecoveryAction(
          label: 'Try Again',
          action: onRetry,
          icon: Icons.refresh,
          isPrimary: true,
        ),
      RecoveryAction(
        label: 'Contact Support',
        action: () => _contactSupport(context),
        icon: Icons.help_outline,
      ),
    ];
  }

  // Helper methods for navigation and actions - simplified for data-driven approach

  static void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact support at support@arkadtlth.se'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Timeline info dialog removed - not needed in data-driven approach
}
