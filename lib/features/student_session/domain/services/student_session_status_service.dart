import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../entities/student_session_application.dart';
import 'student_session_data_service.dart';

/// Domain service for consistent status determination across all student session screens
/// Centralizes all status logic without presentation concerns (colors, icons)
class StudentSessionStatusService {
  const StudentSessionStatusService._();

  static const StudentSessionStatusService instance =
      StudentSessionStatusService._();

  /// Get unified status information for a student session with application state
  /// This is the authoritative method for determining what status to display
  StudentSessionStatusInfo getStatusInfo(
    StudentSessionWithApplicationState sessionWithApp,
  ) {
    // Check if session is available first
    if (!sessionWithApp.session.isAvailable) {
      return const StudentSessionStatusInfo(
        displayText: 'Not available',
        badgeText: null,
        canApply: false,
        canBook: false,
        hasBooking: false,
      );
    }

    // Get effective application status
    final applicationStatus = sessionWithApp.effectiveApplicationStatus;

    if (applicationStatus == null) {
      // No application - check if can apply
      final timelineStatus = TimelineValidationService.checkApplicationPeriod();
      return StudentSessionStatusInfo(
        displayText: 'Available',
        badgeText: null,
        canApply: timelineStatus.canApply,
        canBook: false,
        hasBooking: false,
      );
    }

    // Has application - show application status
    switch (applicationStatus) {
      case ApplicationStatus.pending:
        return const StudentSessionStatusInfo(
          displayText: 'Under Review',
          badgeText: 'Pending',
          canApply: false,
          canBook: false,
          hasBooking: false,
        );

      case ApplicationStatus.accepted:
        final timelineStatus = TimelineValidationService.checkBookingPeriod();
        final hasBooking = sessionWithApp.hasBooking;

        return StudentSessionStatusInfo(
          displayText: 'You were accepted!',
          badgeText: 'Accepted!',
          canApply: false,
          canBook: timelineStatus.canBook && !hasBooking,
          hasBooking: hasBooking,
        );

      case ApplicationStatus.rejected:
        return const StudentSessionStatusInfo(
          displayText: 'Not Selected',
          badgeText: 'Rejected',
          canApply: false,
          canBook: false,
          hasBooking: false,
        );
    }
  }

  /// Get action button information for a session
  ActionButtonInfo getActionButtonInfo(
    StudentSessionWithApplicationState sessionWithApp,
  ) {
    final statusInfo = getStatusInfo(sessionWithApp);

    if (statusInfo.canApply) {
      return const ActionButtonInfo(
        text: 'Apply',
        action: ActionType.apply,
        isEnabled: true,
      );
    }

    if (statusInfo.canBook) {
      return const ActionButtonInfo(
        text: 'Book Timeslot',
        action: ActionType.bookTimeslot,
        isEnabled: true,
      );
    }

    if (statusInfo.hasBooking) {
      return const ActionButtonInfo(
        text: 'Manage Booking',
        action: ActionType.manageBooking,
        isEnabled: true,
      );
    }

    // No actions available
    return ActionButtonInfo(
      text: _getDisabledButtonText(sessionWithApp),
      action: ActionType.none,
      isEnabled: false,
    );
  }

  /// Get status information for applications in profile view
  StudentSessionStatusInfo getApplicationStatusInfo(
    StudentSessionApplicationWithBookingState appWithBooking,
  ) {
    final status = appWithBooking.application.status;

    switch (status) {
      case ApplicationStatus.pending:
        return const StudentSessionStatusInfo(
          displayText: 'Under Review',
          badgeText: 'Under Review',
          canApply: false,
          canBook: false,
          hasBooking: false,
        );

      case ApplicationStatus.accepted:
        final timelineStatus = TimelineValidationService.checkBookingPeriod();
        final hasBooking = appWithBooking.hasBooking;

        return StudentSessionStatusInfo(
          displayText: hasBooking
              ? 'Booking confirmed'
              : 'Ready to book timeslot',
          badgeText: 'You were accepted!',
          canApply: false,
          canBook: timelineStatus.canBook && !hasBooking,
          hasBooking: hasBooking,
        );

      case ApplicationStatus.rejected:
        return const StudentSessionStatusInfo(
          displayText: 'Not Selected',
          badgeText: 'Not Selected',
          canApply: false,
          canBook: false,
          hasBooking: false,
        );
    }
  }

  // Private helper methods

  String _getDisabledButtonText(
    StudentSessionWithApplicationState sessionWithApp,
  ) {
    final applicationStatus = sessionWithApp.effectiveApplicationStatus;

    if (applicationStatus == ApplicationStatus.accepted) {
      final timelineStatus = TimelineValidationService.checkBookingPeriod();
      if (!timelineStatus.canBook) {
        return timelineStatus.phase == StudentSessionPhase.beforeBooking
            ? 'Booking Opens Later'
            : 'Booking Ended';
      }
    }

    if (applicationStatus == ApplicationStatus.rejected) {
      return 'Application Rejected';
    }

    if (applicationStatus == ApplicationStatus.pending) {
      return 'Application Pending';
    }

    // No application yet but can't apply
    final timelineStatus = TimelineValidationService.checkApplicationPeriod();
    if (!timelineStatus.canApply) {
      return timelineStatus.phase == StudentSessionPhase.beforeApplication
          ? 'Applications Open Later'
          : 'Applications Closed';
    }

    return 'Not Available';
  }
}

/// Domain status information for a student session (no UI concerns)
class StudentSessionStatusInfo {
  const StudentSessionStatusInfo({
    required this.displayText,
    required this.badgeText,
    required this.canApply,
    required this.canBook,
    required this.hasBooking,
  });

  /// Text to display for the status (e.g., "Available", "Pending", "Accepted")
  final String displayText;

  /// Text for status badge (null if no badge should be shown)
  final String? badgeText;

  /// Whether the user can apply to this session
  final bool canApply;

  /// Whether the user can book a timeslot for this session
  final bool canBook;

  /// Whether the user has a booking for this session
  final bool hasBooking;
}

/// Domain information about an action button for a session (no UI concerns)
class ActionButtonInfo {
  const ActionButtonInfo({
    required this.text,
    required this.action,
    required this.isEnabled,
  });

  /// Text to display on the button
  final String text;

  /// Type of action this button performs
  final ActionType action;

  /// Whether the button is enabled
  final bool isEnabled;
}

/// Types of actions that can be performed on a student session
enum ActionType { apply, bookTimeslot, manageBooking, none }
