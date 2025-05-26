import 'package:flutter/material.dart';

class TimeSlot {
  final DateTime start;
  final Duration duration; // Change this to Duration instead of DateTime

  TimeSlot(this.start, this.duration);
}

/// AuthProvider manages authentication state throughout the app
class StudentSessionProvider with ChangeNotifier {
  // Public value notifier for widgets that only need to know if user is authenticated
  final ValueNotifier<bool> authState = ValueNotifier<bool>(false);

  /// Creates a new AuthProvider with required services
  StudentSessionProvider();

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
    // Example: return two slots with proper Duration objects
    return [
      TimeSlot(DateTime(2025, 5, 27, 9, 0), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 27, 10, 0), const Duration(minutes: 30)),
    ];
  }
}
