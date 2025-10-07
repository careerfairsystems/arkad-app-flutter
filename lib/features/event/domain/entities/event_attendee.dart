/// Domain entity representing an event attendee
class EventAttendee {
  const EventAttendee({
    required this.fullName,
    this.foodPreferences,
    this.hasBeenScanned = false,
  });

  final String fullName;
  final String? foodPreferences;

  /// Whether the attendee's ticket has been scanned at the event
  /// TODO: This field will be populated once backend is updated with scan tracking
  /// Currently defaults to false
  final bool hasBeenScanned;

  /// Create a copy with updated values
  EventAttendee copyWith({
    String? fullName,
    String? foodPreferences,
    bool? hasBeenScanned,
  }) {
    return EventAttendee(
      fullName: fullName ?? this.fullName,
      foodPreferences: foodPreferences ?? this.foodPreferences,
      hasBeenScanned: hasBeenScanned ?? this.hasBeenScanned,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAttendee &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          foodPreferences == other.foodPreferences &&
          hasBeenScanned == other.hasBeenScanned;

  @override
  int get hashCode => Object.hash(fullName, foodPreferences, hasBeenScanned);

  @override
  String toString() =>
      'EventAttendee(fullName: $fullName, hasBeenScanned: $hasBeenScanned)';
}
