import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

import '../api/extensions.dart';

/// Model for managing student session applications and timeslots
class StudentSessionModel with ChangeNotifier {
  final ArkadApi _apiService = GetIt.I<ArkadApi>();
  
  bool _isLoading = false;
  String? _error;
  List<StudentSessionApplicationOutSchema> _applications = [];
  List<TimeslotSchema> _availableTimeslots = [];

  /// Creates a new StudentSessionModel
  StudentSessionModel();

  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<StudentSessionApplicationOutSchema> get applications => _applications;
  List<TimeslotSchema> get availableTimeslots => _availableTimeslots;

  /// Get student sessions for the current user
  Future<bool> loadSessions() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStudentSessionsApi().studentSessionsApiGetStudentSessions();
      
      if (response.isSuccess && response.data != null) {
        // Convert StudentSessionNormalUserListSchema to individual applications
        // This is a simplified approach - adjust based on actual data structure needs
        notifyListeners();
        return true;
      } else {
        _setError('Failed to load sessions: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error loading sessions: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get available timeslots for a specific company
  Future<bool> loadTimeslots(int companyId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStudentSessionsApi().studentSessionsApiGetStudentSessionTimeslots(companyId: companyId);
      
      if (response.isSuccess && response.data != null) {
        _availableTimeslots = response.data!.toList();
        notifyListeners();
        return true;
      } else {
        _setError('Failed to load timeslots: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error loading timeslots: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Apply for a student session
  Future<bool> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    bool updateProfile = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final application = StudentSessionApplicationSchema((b) => b
        ..companyId = companyId
        ..motivationText = motivationText
        ..programme = programme
        ..linkedin = linkedin
        ..masterTitle = masterTitle
        ..studyYear = studyYear
        ..updateProfile = updateProfile
      );

      final response = await _apiService.getStudentSessionsApi().studentSessionsApiApplyForSession(
        studentSessionApplicationSchema: application,
      );
      
      if (response.isSuccess) {
        // Reload sessions to get updated list
        await loadSessions();
        return true;
      } else {
        _setError('Failed to apply for session: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error applying for session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unbook/cancel a student session
  Future<bool> unbookSession(int companyId) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.getStudentSessionsApi().studentSessionsApiUnbookStudentSession(
        companyId: companyId,
      );
      
      if (response.isSuccess) {
        // Reload sessions to get updated list
        await loadSessions();
        return true;
      } else {
        _setError('Failed to unbook session: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Error unbooking session: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
