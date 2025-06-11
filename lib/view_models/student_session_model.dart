import 'package:flutter/material.dart';

class TimeSlot {
  final DateTime start;
  final Duration duration;

  TimeSlot(this.start, this.duration);

  @override
  String toString() {
    return 'TimeSlot(start: $start, duration: $duration)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeSlot &&
        other.start == start &&
        other.duration == duration;
  }

  @override
  int get hashCode => start.hashCode ^ duration.hashCode;
}

/// AuthProvider manages authentication state throughout the app
class StudentSessionModel with ChangeNotifier {
  // Public value notifier for widgets that only need to know if user is authenticated
  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  /// Creates a new AuthProvider with required services
  StudentSessionModel();

  Future<bool> resetPassword(
    String? cv,
    String? profilePicture,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    String? motivationText,
    bool? updateProfile,
    int? companyId,
  ) async {
    return true;
  }

  Future<List<TimeSlot>> getAvailableSlots(int companyId) async {
    print('getAvailableSlots called for company: $companyId');

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final slots = [
      TimeSlot(DateTime(2025, 5, 27, 9, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 27, 10, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 27, 11, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 13, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 14, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 15, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 29, 9, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 29, 10, 0), const Duration(minutes: 30)),
    ];

    print('Returning ${slots.length} slots: $slots');
    return slots;
  }
}
