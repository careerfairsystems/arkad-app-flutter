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

/// Timeline validation error for student session operations
class StudentSessionTimelineError extends AppError {
  const StudentSessionTimelineError({
    required String message,
    this.applicationStart,
    this.applicationEnd,
    this.bookingStart,
    this.bookingEnd,
    this.currentPhase,
  }) : super(userMessage: message, severity: ErrorSeverity.warning);

  final DateTime? applicationStart;
  final DateTime? applicationEnd;
  final DateTime? bookingStart;
  final DateTime? bookingEnd;
  final StudentSessionPhase? currentPhase;

  /// Get formatted timeline information for display
  String get timelineInfo {
    if (applicationStart != null && applicationEnd != null) {
      return 'Application period: ${_formatDate(applicationStart!)} - ${_formatDate(applicationEnd!)}';
    }
    if (bookingStart != null && bookingEnd != null) {
      return 'Booking period: ${_formatDateTime(bookingStart!)} - ${_formatDateTime(bookingEnd!)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}

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

/// Timeline phases for student session operations
enum StudentSessionPhase {
  beforeApplication('Before Application Period'),
  applicationOpen('Application Period'),
  applicationClosed('Application Closed'),
  beforeBooking('Before Booking Period'),
  bookingOpen('Booking Period'),
  bookingClosed('Booking Closed'),
  sessionComplete('Session Complete');

  const StudentSessionPhase(this.displayName);

  final String displayName;

  /// Check if applications are allowed in this phase
  bool get canApply => this == StudentSessionPhase.applicationOpen;

  /// Check if bookings are allowed in this phase
  bool get canBook => this == StudentSessionPhase.bookingOpen;

  /// Check if the phase is active (can perform operations)
  bool get isActive => canApply || canBook;
}

/// Recovery actions for student session errors
class StudentSessionRecoveryActions {
  /// Create recovery actions for timeline errors
  static List<RecoveryAction> forTimelineError(
    StudentSessionTimelineError error,
    BuildContext? context,
  ) {
    if (context == null) return [];

    final actions = <RecoveryAction>[];

    switch (error.currentPhase) {
      case StudentSessionPhase.beforeApplication:
        actions.add(
          RecoveryAction(
            label: 'Set Reminder',
            action: () => _showReminderDialog(context, error.applicationStart),
            icon: Icons.notification_add,
            isPrimary: true,
          ),
        );

      case StudentSessionPhase.applicationClosed:
        actions.add(
          RecoveryAction(
            label: 'Browse Other Companies',
            action: () => _navigateToCompanies(context),
            icon: Icons.business,
            isPrimary: true,
          ),
        );

      case StudentSessionPhase.beforeBooking:
        actions.add(
          RecoveryAction(
            label: 'View My Applications',
            action: () => _navigateToProfile(context),
            icon: Icons.assignment,
            isPrimary: true,
          ),
        );

      case StudentSessionPhase.bookingClosed:
        actions.add(
          RecoveryAction(
            label: 'Contact Support',
            action: () => _contactSupport(context),
            icon: Icons.help_outline,
          ),
        );

      default:
    }

    // Always add a "Learn More" action
    actions.add(
      RecoveryAction(
        label: 'Learn More',
        action: () => _showTimelineInfo(context, error),
        icon: Icons.info_outline,
      ),
    );

    return actions;
  }

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
        label: 'Save Draft',
        action: () => _saveDraft(context),
        icon: Icons.save,
      ),
      RecoveryAction(
        label: 'Contact Support',
        action: () => _contactSupport(context),
        icon: Icons.help_outline,
      ),
    ];
  }

  // Helper methods for navigation and actions
  static void _showReminderDialog(
    BuildContext context,
    DateTime? reminderTime,
  ) {
    // TODO: Implement reminder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Reminder set for ${reminderTime != null ? _formatDate(reminderTime) : 'application period'}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _navigateToCompanies(BuildContext context) {
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil('/companies', (route) => false);
  }

  static void _navigateToProfile(BuildContext context) {
    Navigator.of(context).pushNamed('/profile');
  }

  static void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Contact support at support@arkadtlth.se'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static void _showTimelineInfo(
    BuildContext context,
    StudentSessionTimelineError error,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Student Session Timeline'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(error.userMessage),
                const SizedBox(height: 12),
                if (error.timelineInfo.isNotEmpty) Text(error.timelineInfo),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  static void _saveDraft(BuildContext context) {
    // TODO: Implement draft saving functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved locally'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
