import 'package:flutter/material.dart';

import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../entities/student_session_application.dart';
import 'student_session_data_service.dart';

/// Service for consistent status determination and display across all student session screens
/// Centralizes all status logic to prevent inconsistencies between different parts of the app
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
      return StudentSessionStatusInfo(
        displayText: 'Not available',
        displayColor: _getUnavailableColor(),
        badgeText: null,
        badgeColor: null,
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
        displayColor: ArkadColors.arkadGreen,
        badgeText: null,
        badgeColor: null,
        canApply: timelineStatus.canApply,
        canBook: false,
        hasBooking: false,
      );
    }

    // Has application - show application status
    switch (applicationStatus) {
      case ApplicationStatus.pending:
        return StudentSessionStatusInfo(
          displayText: 'Under Review',
          displayColor: ArkadColors.arkadOrange,
          badgeText: 'Pending',
          badgeColor: ArkadColors.arkadOrange,
          canApply: false,
          canBook: false,
          hasBooking: false,
        );

      case ApplicationStatus.accepted:
        final timelineStatus = TimelineValidationService.checkBookingPeriod();
        final hasBooking = sessionWithApp.hasBooking;

        return StudentSessionStatusInfo(
          displayText: 'You were accepted!',
          displayColor: ArkadColors.arkadGreen,
          badgeText: 'Accepted!',
          badgeColor: ArkadColors.arkadGreen,
          canApply: false,
          canBook: timelineStatus.canBook && !hasBooking,
          hasBooking: hasBooking,
        );

      case ApplicationStatus.rejected:
        return StudentSessionStatusInfo(
          displayText: 'Not Selected',
          displayColor: ArkadColors.lightRed,
          badgeText: 'Rejected',
          badgeColor: ArkadColors.lightRed,
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
      return ActionButtonInfo(
        text: 'Apply',
        icon: Icons.send_rounded,
        color: ArkadColors.arkadTurkos,
        action: ActionType.apply,
        isEnabled: true,
      );
    }

    if (statusInfo.canBook) {
      return ActionButtonInfo(
        text: 'Book Timeslot',
        icon: Icons.schedule_rounded,
        color: ArkadColors.arkadTurkos,
        action: ActionType.bookTimeslot,
        isEnabled: true,
      );
    }

    if (statusInfo.hasBooking) {
      return ActionButtonInfo(
        text: 'Manage Booking',
        icon: Icons.edit_calendar_rounded,
        color: ArkadColors.arkadTurkos,
        action: ActionType.manageBooking,
        isEnabled: true,
      );
    }

    // No actions available
    return ActionButtonInfo(
      text: _getDisabledButtonText(sessionWithApp),
      icon: _getDisabledButtonIcon(sessionWithApp),
      color: _getDisabledButtonColor(),
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
        return StudentSessionStatusInfo(
          displayText: 'Under Review',
          displayColor: ArkadColors.arkadOrange,
          badgeText: 'Under Review',
          badgeColor: ArkadColors.arkadOrange,
          canApply: false,
          canBook: false,
          hasBooking: false,
        );

      case ApplicationStatus.accepted:
        final timelineStatus = TimelineValidationService.checkBookingPeriod();
        final hasBooking = appWithBooking.hasBooking;

        return StudentSessionStatusInfo(
          displayText:
              hasBooking ? 'Booking confirmed' : 'Ready to book timeslot',
          displayColor: ArkadColors.arkadGreen,
          badgeText: 'You were accepted!',
          badgeColor: ArkadColors.arkadGreen,
          canApply: false,
          canBook: timelineStatus.canBook && !hasBooking,
          hasBooking: hasBooking,
        );

      case ApplicationStatus.rejected:
        return StudentSessionStatusInfo(
          displayText: 'Not Selected',
          displayColor: ArkadColors.lightRed,
          badgeText: 'Not Selected',
          badgeColor: ArkadColors.lightRed,
          canApply: false,
          canBook: false,
          hasBooking: false,
        );
    }
  }

  // Private helper methods

  Color _getUnavailableColor() {
    // Use a neutral color for unavailable sessions
    return Colors.grey;
  }

  Color _getDisabledButtonColor() {
    return Colors.grey;
  }

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

  IconData _getDisabledButtonIcon(
    StudentSessionWithApplicationState sessionWithApp,
  ) {
    final applicationStatus = sessionWithApp.effectiveApplicationStatus;

    if (applicationStatus == ApplicationStatus.accepted) {
      return Icons.schedule_rounded;
    }

    if (applicationStatus != null) {
      return Icons.info_outline_rounded;
    }

    return Icons.send_rounded;
  }
}

/// Comprehensive status information for a student session
class StudentSessionStatusInfo {
  const StudentSessionStatusInfo({
    required this.displayText,
    required this.displayColor,
    required this.badgeText,
    required this.badgeColor,
    required this.canApply,
    required this.canBook,
    required this.hasBooking,
  });

  /// Text to display for the status (e.g., "Available", "Pending", "Accepted")
  final String displayText;

  /// Color to use for the status display
  final Color displayColor;

  /// Text for status badge (null if no badge should be shown)
  final String? badgeText;

  /// Color for status badge (null if no badge should be shown)
  final Color? badgeColor;

  /// Whether the user can apply to this session
  final bool canApply;

  /// Whether the user can book a timeslot for this session
  final bool canBook;

  /// Whether the user has a booking for this session
  final bool hasBooking;
}

/// Information about the action button for a session
class ActionButtonInfo {
  const ActionButtonInfo({
    required this.text,
    required this.icon,
    required this.color,
    required this.action,
    required this.isEnabled,
  });

  /// Text to display on the button
  final String text;

  /// Icon to display on the button
  final IconData icon;

  /// Color of the button
  final Color color;

  /// Type of action this button performs
  final ActionType action;

  /// Whether the button is enabled
  final bool isEnabled;
}

/// Types of actions that can be performed on a student session
enum ActionType { apply, bookTimeslot, manageBooking, none }
