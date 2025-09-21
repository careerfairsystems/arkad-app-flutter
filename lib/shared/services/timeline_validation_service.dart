import '../errors/student_session_errors.dart';

/// Service for validating student session timeline constraints
/// Enforces the exact dates from requirements (adjusted for testing):
/// - Application Period: Sep 10-30, 2025
/// - Booking Period: Sep 15 09:00 - Oct 5 23:59, 2025
class TimelineValidationService {
  // Timeline constants from requirements (adjusted for testing)
  static final DateTime applicationStart = DateTime(2025, 9, 10);
  static final DateTime applicationEnd = DateTime(2025, 9, 30, 23, 59, 59);
  static final DateTime bookingStart = DateTime(2025, 9, 15, 9);
  static final DateTime bookingEnd = DateTime(2025, 10, 5, 23, 59, 59);

  /// Check if applications are currently allowed
  static TimelineStatus checkApplicationPeriod({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    if (now.isBefore(applicationStart)) {
      return TimelineStatus(
        canApply: false,
        canBook: false,
        phase: StudentSessionPhase.beforeApplication,
        reason: 'Applications open on ${_formatDate(applicationStart)}',
        applicationStart: applicationStart,
        applicationEnd: applicationEnd,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
    }

    if (now.isAfter(applicationEnd)) {
      return TimelineStatus(
        canApply: false,
        canBook: false,
        phase: StudentSessionPhase.applicationClosed,
        reason: 'Application period ended on ${_formatDate(applicationEnd)}',
        applicationStart: applicationStart,
        applicationEnd: applicationEnd,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
    }

    return TimelineStatus(
      canApply: true,
      canBook: false,
      phase: StudentSessionPhase.applicationOpen,
      reason: 'Applications are open until ${_formatDate(applicationEnd)}',
      applicationStart: applicationStart,
      applicationEnd: applicationEnd,
      bookingStart: bookingStart,
      bookingEnd: bookingEnd,
    );
  }

  /// Check if booking is currently allowed
  static TimelineStatus checkBookingPeriod({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    if (now.isBefore(bookingStart)) {
      return TimelineStatus(
        canApply: false,
        canBook: false,
        phase: StudentSessionPhase.beforeBooking,
        reason: 'Booking opens on ${_formatDateTime(bookingStart)}',
        applicationStart: applicationStart,
        applicationEnd: applicationEnd,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
    }

    if (now.isAfter(bookingEnd)) {
      return TimelineStatus(
        canApply: false,
        canBook: false,
        phase: StudentSessionPhase.bookingClosed,
        reason: 'Booking period ended on ${_formatDateTime(bookingEnd)}',
        applicationStart: applicationStart,
        applicationEnd: applicationEnd,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
    }

    return TimelineStatus(
      canApply: false,
      canBook: true,
      phase: StudentSessionPhase.bookingOpen,
      reason: 'Booking is open until ${_formatDateTime(bookingEnd)}',
      applicationStart: applicationStart,
      applicationEnd: applicationEnd,
      bookingStart: bookingStart,
      bookingEnd: bookingEnd,
    );
  }

  /// Get current timeline status (combines application and booking periods)
  static TimelineStatus getCurrentStatus({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();

    // Check application period first
    if (now.isBefore(applicationStart)) {
      return checkApplicationPeriod(currentTime: now);
    }

    if (now.isBefore(applicationEnd)) {
      return checkApplicationPeriod(currentTime: now);
    }

    // Application period is over, check booking period
    if (now.isBefore(bookingStart)) {
      return TimelineStatus(
        canApply: false,
        canBook: false,
        phase: StudentSessionPhase.applicationClosed,
        reason:
            'Applications closed. Booking opens on ${_formatDateTime(bookingStart)}',
        applicationStart: applicationStart,
        applicationEnd: applicationEnd,
        bookingStart: bookingStart,
        bookingEnd: bookingEnd,
      );
    }

    if (now.isBefore(bookingEnd)) {
      return checkBookingPeriod(currentTime: now);
    }

    // Everything is over
    return TimelineStatus(
      canApply: false,
      canBook: false,
      phase: StudentSessionPhase.bookingClosed,
      reason: 'Student session period has ended',
      applicationStart: applicationStart,
      applicationEnd: applicationEnd,
      bookingStart: bookingStart,
      bookingEnd: bookingEnd,
    );
  }

  /// Validate if application is allowed at current time
  static void validateApplicationAllowed({DateTime? currentTime}) {
    final status = checkApplicationPeriod(currentTime: currentTime);
    if (!status.canApply) {
      throw StudentSessionTimelineError(
        message: status.reason,
        applicationStart: status.applicationStart,
        applicationEnd: status.applicationEnd,
        bookingStart: status.bookingStart,
        bookingEnd: status.bookingEnd,
        currentPhase: status.phase,
      );
    }
  }

  /// Validate if booking is allowed at current time
  static void validateBookingAllowed({DateTime? currentTime}) {
    final status = checkBookingPeriod(currentTime: currentTime);
    if (!status.canBook) {
      throw StudentSessionTimelineError(
        message: status.reason,
        applicationStart: status.applicationStart,
        applicationEnd: status.applicationEnd,
        bookingStart: status.bookingStart,
        bookingEnd: status.bookingEnd,
        currentPhase: status.phase,
      );
    }
  }

  /// Get time remaining until next phase
  static Duration? getTimeUntilNextPhase({DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final status = getCurrentStatus(currentTime: now);

    switch (status.phase) {
      case StudentSessionPhase.beforeApplication:
        return applicationStart.difference(now);
      case StudentSessionPhase.applicationOpen:
        return applicationEnd.difference(now);
      case StudentSessionPhase.applicationClosed:
      case StudentSessionPhase.beforeBooking:
        return bookingStart.difference(now);
      case StudentSessionPhase.bookingOpen:
        return bookingEnd.difference(now);
      case StudentSessionPhase.bookingClosed:
      case StudentSessionPhase.sessionComplete:
        return null; // No next phase
    }
  }

  /// Check if given time is within application period
  static bool isWithinApplicationPeriod(DateTime time) {
    return time.isAfter(applicationStart) && time.isBefore(applicationEnd);
  }

  /// Check if given time is within booking period
  static bool isWithinBookingPeriod(DateTime time) {
    return time.isAfter(bookingStart) && time.isBefore(bookingEnd);
  }

  /// Format date for display (e.g., "13 Oct 2024")
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

  /// Format date and time for display (e.g., "2 Nov 2024 at 17:00")
  static String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

/// Timeline status information
class TimelineStatus {
  const TimelineStatus({
    required this.canApply,
    required this.canBook,
    required this.phase,
    required this.reason,
    this.applicationStart,
    this.applicationEnd,
    this.bookingStart,
    this.bookingEnd,
  });

  /// Whether applications are allowed
  final bool canApply;

  /// Whether booking is allowed
  final bool canBook;

  /// Current timeline phase
  final StudentSessionPhase phase;

  /// Human-readable reason/message
  final String reason;

  /// Application period start
  final DateTime? applicationStart;

  /// Application period end
  final DateTime? applicationEnd;

  /// Booking period start
  final DateTime? bookingStart;

  /// Booking period end
  final DateTime? bookingEnd;

  /// Check if any operation is allowed
  bool get isActive => canApply || canBook;

  /// Get formatted timeline information
  String get timelineInfo {
    final parts = <String>[];

    if (applicationStart != null && applicationEnd != null) {
      parts.add(
        'Application: ${TimelineValidationService._formatDate(applicationStart!)} - ${TimelineValidationService._formatDate(applicationEnd!)}',
      );
    }

    if (bookingStart != null && bookingEnd != null) {
      parts.add(
        'Booking: ${TimelineValidationService._formatDateTime(bookingStart!)} - ${TimelineValidationService._formatDateTime(bookingEnd!)}',
      );
    }

    return parts.join('\n');
  }

  @override
  String toString() {
    return 'TimelineStatus(phase: $phase, canApply: $canApply, canBook: $canBook, reason: $reason)';
  }
}
