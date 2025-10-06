import '../../../../shared/infrastructure/services/timezone_service.dart';
import '../entities/student_session.dart';
import '../entities/timeslot.dart';

/// Centralized service for timeline validation logic across student session features
/// Provides consistent validation rules for TWO separate periods:
/// 1. Application Period: Session-level bookingOpenTime/bookingCloseTime (when users can apply)
/// 2. Booking Period: Timeslot-level bookingClosesAt (when accepted users can book timeslots)
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
  /// Note: Booking period is separate from application period and depends on individual timeslots
  bool isBookingPeriodActive(StudentSession session, {DateTime? now}) {
    // User must be accepted to book timeslots
    if (!session.isAccepted) return false;

    // For booking period, we need to check individual timeslots
    // This method provides a session-level check, but actual booking
    // should use isTimeslotBookingOpen() for individual timeslots
    return true; // If accepted, booking availability depends on individual timeslots
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
  /// Note: Booking period status is session-level only; individual timeslots have their own deadlines
  TimelineStatus getTimelineStatus(StudentSession session, {DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    // Check application period (session-level)
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

    // Booking period is session-level: simple acceptance-based check
    // Individual timeslots have their own deadlines checked separately
    final bookingPeriodActive =
        session.isAccepted && isBookingPeriodActive(session, now: currentTime);

    // At session level, booking doesn't have past/upcoming states
    // because booking availability depends on individual timeslot deadlines
    const bookingPeriodPassed = false;
    const bookingPeriodUpcoming = false;

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
    final currentTime = now ?? TimezoneService.stockholmNow();

    // Since domain entities already contain Stockholm time, we can compare directly
    if (session.bookingOpenTime != null &&
        currentTime.isBefore(session.bookingOpenTime!)) {
      return 'Applications open on ${TimezoneService.formatDateTime(session.bookingOpenTime!)}';
    }

    if (session.bookingCloseTime != null &&
        currentTime.isAfter(session.bookingCloseTime!)) {
      return 'Application period has ended';
    }

    return null; // No special timeline message needed
  }

  /// Get booking-specific timeline message for a timeslot
  /// Returns appropriate message based on timeslot booking deadline
  String? getTimeslotBookingMessage(Timeslot timeslot, {DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    if (timeslot.bookingClosesAt != null &&
        currentTime.isAfter(timeslot.bookingClosesAt!)) {
      return 'Booking closed on ${TimezoneService.formatDateTime(timeslot.bookingClosesAt!)}';
    }

    // If booking is still open but has a deadline, show it
    if (timeslot.bookingClosesAt != null) {
      final timeUntilDeadline = timeslot.bookingClosesAt!.difference(
        currentTime,
      );

      if (timeUntilDeadline.inHours < 24) {
        return 'Booking closes today at ${TimezoneService.formatTime(timeslot.bookingClosesAt!)}';
      } else if (timeUntilDeadline.inDays < 7) {
        return 'Booking closes on ${TimezoneService.formatDateTime(timeslot.bookingClosesAt!)}';
      }
    }

    return null;
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
