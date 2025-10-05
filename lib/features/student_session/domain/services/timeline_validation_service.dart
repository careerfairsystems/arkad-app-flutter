import '../entities/student_session.dart';
import '../entities/timeslot.dart';

/// Centralized service for timeline validation logic across student session features
/// Provides consistent validation rules for application and booking periods
class TimelineValidationService {
  const TimelineValidationService._();

  static const TimelineValidationService instance =
      TimelineValidationService._();

  /// Check if application period is currently active for a session
  /// Returns true if applications can be submitted now
  bool isApplicationPeriodActive(StudentSession session, {DateTime? now}) {
    return session.isApplicationPeriodActive(now: now);
  }

  /// Check if booking period is currently active for a session
  /// Returns true if timeslots can be booked/managed now
  bool isBookingPeriodActive(StudentSession session, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    // If no booking times are set, use basic acceptance status
    if (session.bookingOpenTime == null && session.bookingCloseTime == null) {
      return session.isAccepted;
    }

    // Check if current time is within the booking window
    final isAfterOpen =
        session.bookingOpenTime == null ||
        !currentTime.isBefore(session.bookingOpenTime!);
    final isBeforeClose =
        session.bookingCloseTime == null ||
        !currentTime.isAfter(session.bookingCloseTime!);

    return session.isAccepted && isAfterOpen && isBeforeClose;
  }

  /// Check if timeslot booking is still open
  /// Returns true if the specific timeslot can still be booked
  bool isTimeslotBookingOpen(Timeslot timeslot, {DateTime? now}) {
    return timeslot.isBookingStillOpen(now: now);
  }

  /// Check if user can show the Apply button for a session
  /// Combines session availability, user status, and timeline validation
  bool canShowApplyButton(StudentSession session, {DateTime? now}) {
    // Must be able to apply and within application period
    return session.canApply && isApplicationPeriodActive(session, now: now);
  }

  /// Check if user can navigate to application form
  /// Similar to canShowApplyButton but may have different logic in future
  bool canNavigateToApplication(StudentSession session, {DateTime? now}) {
    return canShowApplyButton(session, now: now);
  }

  /// Check if user can book timeslots for a session
  /// Combines acceptance status and booking period validation
  bool canBookTimeslots(StudentSession session, {DateTime? now}) {
    return session.isAccepted && isBookingPeriodActive(session, now: now);
  }

  /// Check if user can manage existing bookings
  /// Returns true if booking modifications are still allowed
  bool canManageBooking(StudentSession session, {DateTime? now}) {
    return isBookingPeriodActive(session, now: now);
  }

  /// Get timeline status for a session
  /// Returns comprehensive timeline information for UI decisions
  TimelineStatus getTimelineStatus(StudentSession session, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();

    // Check application period
    final applicationPeriodActive = isApplicationPeriodActive(
      session,
      now: currentTime,
    );
    final applicationPeriodPassed = _isApplicationPeriodPassed(
      session,
      currentTime,
    );
    final applicationPeriodUpcoming = _isApplicationPeriodUpcoming(
      session,
      currentTime,
    );

    // Check booking period (only relevant if user is accepted)
    final bookingPeriodActive =
        session.isAccepted && isBookingPeriodActive(session, now: currentTime);
    final bookingPeriodPassed =
        session.isAccepted && _isBookingPeriodPassed(session, currentTime);
    final bookingPeriodUpcoming =
        session.isAccepted && _isBookingPeriodUpcoming(session, currentTime);

    return TimelineStatus(
      applicationPeriodActive: applicationPeriodActive,
      applicationPeriodPassed: applicationPeriodPassed,
      applicationPeriodUpcoming: applicationPeriodUpcoming,
      bookingPeriodActive: bookingPeriodActive,
      bookingPeriodPassed: bookingPeriodPassed,
      bookingPeriodUpcoming: bookingPeriodUpcoming,
    );
  }

  /// Get user-friendly timeline message for a session
  /// Returns appropriate message based on current timeline status
  String? getTimelineMessage(StudentSession session, {DateTime? now}) {
    final status = getTimelineStatus(session, now: now);

    if (status.applicationPeriodUpcoming) {
      if (session.bookingOpenTime != null) {
        return 'Applications open on ${_formatDateTime(session.bookingOpenTime!)}';
      }
      return 'Applications not yet open';
    }

    if (status.applicationPeriodPassed) {
      return 'Application period has ended';
    }

    if (session.isAccepted) {
      if (status.bookingPeriodUpcoming) {
        if (session.bookingOpenTime != null) {
          return 'Booking opens on ${_formatDateTime(session.bookingOpenTime!)}';
        }
        return 'Booking not yet available';
      }

      if (status.bookingPeriodPassed) {
        return 'Booking period has ended';
      }
    }

    return null; // No special timeline message needed
  }

  // Private helper methods

  bool _isApplicationPeriodPassed(
    StudentSession session,
    DateTime currentTime,
  ) {
    if (session.bookingCloseTime == null) return false;
    return currentTime.isAfter(session.bookingCloseTime!);
  }

  bool _isApplicationPeriodUpcoming(
    StudentSession session,
    DateTime currentTime,
  ) {
    if (session.bookingOpenTime == null) return false;
    return currentTime.isBefore(session.bookingOpenTime!);
  }

  bool _isBookingPeriodPassed(StudentSession session, DateTime currentTime) {
    if (session.bookingCloseTime == null) return false;
    return currentTime.isAfter(session.bookingCloseTime!);
  }

  bool _isBookingPeriodUpcoming(StudentSession session, DateTime currentTime) {
    if (session.bookingOpenTime == null) return false;
    return currentTime.isBefore(session.bookingOpenTime!);
  }

  String _formatDateTime(DateTime dateTime) {
    // Simple formatting - can be enhanced with proper date formatting
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Comprehensive timeline status information for a student session
class TimelineStatus {
  const TimelineStatus({
    required this.applicationPeriodActive,
    required this.applicationPeriodPassed,
    required this.applicationPeriodUpcoming,
    required this.bookingPeriodActive,
    required this.bookingPeriodPassed,
    required this.bookingPeriodUpcoming,
  });

  /// Whether applications can be submitted now
  final bool applicationPeriodActive;

  /// Whether application period has ended
  final bool applicationPeriodPassed;

  /// Whether application period hasn't started yet
  final bool applicationPeriodUpcoming;

  /// Whether timeslots can be booked now (user must be accepted)
  final bool bookingPeriodActive;

  /// Whether booking period has ended
  final bool bookingPeriodPassed;

  /// Whether booking period hasn't started yet
  final bool bookingPeriodUpcoming;

  /// Whether any timeline restriction is active
  bool get hasTimelineRestrictions =>
      applicationPeriodPassed ||
      applicationPeriodUpcoming ||
      bookingPeriodPassed ||
      bookingPeriodUpcoming;

  /// Whether the session is in a "waiting" state (periods haven't started)
  bool get isWaitingForPeriodToStart =>
      applicationPeriodUpcoming || bookingPeriodUpcoming;

  /// Whether all relevant periods have ended
  bool get allPeriodsEnded => applicationPeriodPassed || bookingPeriodPassed;
}
