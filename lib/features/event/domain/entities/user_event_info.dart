/// User information for event verification
class UserEventInfo {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? foodPreferences;

  const UserEventInfo({
    required this.id,
    this.firstName,
    this.lastName,
    this.foodPreferences,
  });

  /// Get full name from first and last name
  String get fullName {
    final first = firstName ?? '';
    final last = lastName ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown User';
    if (first.isEmpty) return last;
    if (last.isEmpty) return first;
    return '$first $last';
  }

  @override
  String toString() => 'UserEventInfo(id: $id, fullName: $fullName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserEventInfo && other.id == id;
  }

  @override
  int get hashCode => id;
}
