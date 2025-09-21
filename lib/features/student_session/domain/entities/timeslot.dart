/// Domain entity representing a student session timeslot
/// Maps from TimeslotSchema in API
class Timeslot {
  const Timeslot({
    required this.id,
    required this.companyId,
    required this.startTime,
    required this.durationMinutes,
    this.maxParticipants,
    this.currentParticipants,
    this.isAvailable = true,
    this.isBooked = false,
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

  /// Whether this timeslot is available for booking
  final bool isAvailable;

  /// Whether this timeslot is booked by current user
  final bool isBooked;

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

  /// Format time range for display
  String get timeRangeDisplay {
    final startStr = _formatTime(startTime);
    final endStr = _formatTime(endTime);
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
    bool? isAvailable,
    bool? isBooked,
  }) {
    return Timeslot(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isAvailable: isAvailable ?? this.isAvailable,
      isBooked: isBooked ?? this.isBooked,
    );
  }

  /// Format date for display
  String get dateDisplay {
    final months = [
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
    return '${startTime.day} ${months[startTime.month - 1]}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
        other.isAvailable == isAvailable &&
        other.isBooked == isBooked;
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
      isAvailable,
      isBooked,
    );
  }

  @override
  String toString() {
    return 'Timeslot(id: $id, timeRange: $timeRangeDisplay, available: $isAvailable)';
  }
}
