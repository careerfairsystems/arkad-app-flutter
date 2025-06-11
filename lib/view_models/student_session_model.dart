import 'dart:io';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:arkad/models/programme.dart';
import 'package:arkad/utils/validation_utils.dart';

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
  final ArkadApi _apiService = GetIt.I<ArkadApi>();

  /// Creates a new AuthProvider with required services
  StudentSessionModel();

  /// Apply to a student session with the provided application data
  Future<bool> applyToSession({
    required int companyId,
    required Programme programme,
    required int studyYear,
    File? cvFile,
    File? motivationFile,
  }) async {
    try {
      // Convert Programme enum to string
      final programmeString = _programmeToString(programme);

      // Create the application schema
      final applicationSchema = StudentSessionApplicationSchema(
        (b) =>
            b
              ..companyId = companyId
              ..programme = programmeString
              ..studyYear = studyYear
              ..updateProfile = false,
      );

      print("TEST");
      // Submit the application
      final response = await _apiService
          .getStudentSessionsApi()
          .studentSessionsApiApplyForSession(
            studentSessionApplicationSchema: applicationSchema,
          );

      if (response.statusCode == 200) {
        print('Successfully applied to session for company $companyId');
        // If CV file is provided, upload it separately
        if (cvFile != null) {
          await _apiService
              .getStudentSessionsApi()
              .studentSessionsApiUpdateCvForSession(
                companyId: companyId,
                cv: await getMultipartFile(cvFile),
              );
        }

        print('Successfully applied to session for company $companyId');
        return true;
      } else {
        print('Failed to apply to session: ${response.statusMessage}');
        return false;
      }
    } catch (e) {
      print('Error applying to session: $e');
      return false;
    }
  }

  /// Convert Programme enum to string for API
  String _programmeToString(Programme programme) {
    // Import the programs list from the programme model
    final programData = programs.firstWhere(
      (prog) => prog['value'] == programme,
      orElse: () => {'label': programme.toString().split('.').last},
    );

    return programData['label'] as String;
  }

  Future<List<TimeSlot>> getAvailableSlots(int companyId) async {
    print('getAvailableSlots called for company: $companyId');

    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    final slots = [
      TimeSlot(DateTime(2025, 5, 27, 9), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 27, 10), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 27, 11), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 13), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 14), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 28, 15), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 29, 9), const Duration(minutes: 30)),
      TimeSlot(DateTime(2025, 5, 29, 10), const Duration(minutes: 30)),
    ];

    print('Returning ${slots.length} slots: $slots');
    return slots;
  }
}
