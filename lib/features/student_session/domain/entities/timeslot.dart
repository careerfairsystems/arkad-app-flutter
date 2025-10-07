import '../../../../shared/infrastructure/services/timezone_service.dart';

/// Status of a timeslot for the current user
/// Maps from TimeslotSchemaUserStatusEnum in API
enum TimeslotStatus {
  free('free'),
  bookedByCurrentUser('bookedByCurrentUser');

  const TimeslotStatus(this.value);

  final String value;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case TimeslotStatus.free:
        return 'Available';
      case TimeslotStatus.bookedByCurrentUser:
        return 'Booked by you';
    }
  }

  /// Create from API string value
  static TimeslotStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in TimeslotStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// Check if timeslot is available for booking
  bool get isAvailable => this == TimeslotStatus.free;

  /// Check if timeslot is booked by current user
  bool get isBookedByCurrentUser => this == TimeslotStatus.bookedByCurrentUser;
}

/// Domain entity representing a student session timeslot
/// Maps from TimeslotSchemaUser in API
class Timeslot {
  const Timeslot({
    required this.id,
    required this.companyId,
    required this.startTime,
    required this.durationMinutes,
    this.maxParticipants,
    this.currentParticipants,
    required this.status,
    this.bookingClosesAt,
  });

  /// Unique identifier for this timeslot
  final int id;

  /// ID of the company this timeslot belongs to
  final int companyId;

  /// Start time of the timeslot
  final DateTime startTime;

  /// Duration in minutes (from API TimeslotSchema)
  final int durationMinutes;

  /// Maximum participants for this timeslot (optional, may not be in API)
  final int? maxParticipants;

  /// Current number of participants (optional, may not be in API)
  final int? currentParticipants;

  /// Status of this timeslot for the current user
  final TimeslotStatus status;

  /// When booking closes for this specific timeslot (optional deadline)
  final DateTime? bookingClosesAt;

  /// Whether this timeslot is available for booking (convenience getter)
  bool get isAvailable => status.isAvailable;

  /// Whether this timeslot is booked by current user (convenience getter)
  bool get isBooked => status.isBookedByCurrentUser;

  /// End time calculated from start time and duration
  DateTime get endTime => startTime.add(Duration(minutes: durationMinutes));

  /// Duration as Duration object
  Duration get duration => Duration(minutes: durationMinutes);

  /// Check if timeslot is full (returns false if capacity info unavailable)
  bool get isFull {
    if (maxParticipants == null || currentParticipants == null) return false;
    return currentParticipants! >= maxParticipants!;
  }

  /// Available spots remaining (returns null if capacity info unavailable)
  int? get spotsRemaining {
    if (maxParticipants == null || currentParticipants == null) return null;
    return maxParticipants! - currentParticipants!;
  }

  /// Check if booking is still open for this timeslot
  bool isBookingStillOpen({DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    // If no booking close time is set, booking is always open
    if (bookingClosesAt == null) {
      return true;
    }

    // Direct comparison since both times are in Stockholm timezone
    return currentTime.isBefore(bookingClosesAt!);
  }

  /// Check if this timeslot can be booked now (combines status and timeline)
  bool get canBookNow => isAvailable && isBookingStillOpen();

  /// Check if this timeslot can be managed now (for existing bookings)
  bool get canManageNow => isBooked && isBookingStillOpen();

  /// Format time range for display in Stockholm time
  String get timeRangeDisplay {
    final startStr = TimezoneService.formatTime(startTime);
    final endStr = TimezoneService.formatTime(endTime);
    return '$startStr - $endStr';
  }

  /// Create a copy with updated values
  Timeslot copyWith({
    int? id,
    int? companyId,
    DateTime? startTime,
    int? durationMinutes,
    int? maxParticipants,
    int? currentParticipants,
    TimeslotStatus? status,
    DateTime? bookingClosesAt,
  }) {
    return Timeslot(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      bookingClosesAt: bookingClosesAt ?? this.bookingClosesAt,
    );
  }

  /// Format date for display in Stockholm time
  String get dateDisplay {
    return TimezoneService.formatDate(startTime);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Timeslot &&
        other.id == id &&
        other.companyId == companyId &&
        other.startTime == startTime &&
        other.durationMinutes == durationMinutes &&
        other.maxParticipants == maxParticipants &&
        other.currentParticipants == currentParticipants &&
        other.status == status &&
        other.bookingClosesAt == bookingClosesAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      startTime,
      durationMinutes,
      maxParticipants,
      currentParticipants,
      status,
      bookingClosesAt,
    );
  }

  @override
  String toString() {
    return 'Timeslot(id: $id, companyId: $companyId)';
  }
}
