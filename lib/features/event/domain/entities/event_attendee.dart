/// Domain entity representing an event attendee
class EventAttendee {
  const EventAttendee({
    required this.fullName,
    this.foodPreferences,
  });

  final String fullName;
  final String? foodPreferences;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventAttendee &&
          runtimeType == other.runtimeType &&
          fullName == other.fullName &&
          foodPreferences == other.foodPreferences;

  @override
  int get hashCode => Object.hash(fullName, foodPreferences);

  @override
  String toString() => 'EventAttendee(fullName: $fullName)';
}