/// Domain entity representing a student session timeslot
class Timeslot {
  final int id;
  final int companyId;
  final DateTime startTime;
  final DateTime endTime;
  final int maxParticipants;
  final int currentParticipants;
  final bool isAvailable;

  const Timeslot({
    required this.id,
    required this.companyId,
    required this.startTime,
    required this.endTime,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.isAvailable,
  });

  /// Create a copy with updated values
  Timeslot copyWith({
    int? id,
    int? companyId,
    DateTime? startTime,
    DateTime? endTime,
    int? maxParticipants,
    int? currentParticipants,
    bool? isAvailable,
  }) {
    return Timeslot(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  /// Duration of the timeslot
  Duration get duration => endTime.difference(startTime);

  /// Check if timeslot is full
  bool get isFull => currentParticipants >= maxParticipants;

  /// Available spots remaining
  int get spotsRemaining => maxParticipants - currentParticipants;

  /// Format time range for display
  String get timeRangeDisplay {
    final startStr = _formatTime(startTime);
    final endStr = _formatTime(endTime);
    return '$startStr - $endStr';
  }

  /// Format date for display
  String get dateDisplay {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
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
        other.endTime == endTime &&
        other.maxParticipants == maxParticipants &&
        other.currentParticipants == currentParticipants &&
        other.isAvailable == isAvailable;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      startTime,
      endTime,
      maxParticipants,
      currentParticipants,
      isAvailable,
    );
  }

  @override
  String toString() {
    return 'Timeslot(id: $id, timeRange: $timeRangeDisplay, available: $isAvailable)';
  }
}