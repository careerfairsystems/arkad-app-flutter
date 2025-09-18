import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/use_cases/apply_for_session_use_case.dart';
import '../../domain/use_cases/cancel_application_use_case.dart';
import '../../domain/use_cases/get_student_sessions_use_case.dart';

/// ViewModel for managing student session state and operations
class StudentSessionViewModel extends ChangeNotifier {
  final GetStudentSessionsUseCase _getStudentSessionsUseCase;
  final ApplyForSessionUseCase _applyForSessionUseCase;
  final CancelApplicationUseCase _cancelApplicationUseCase;

  StudentSessionViewModel({
    required GetStudentSessionsUseCase getStudentSessionsUseCase,
    required ApplyForSessionUseCase applyForSessionUseCase,
    required CancelApplicationUseCase cancelApplicationUseCase,
  }) : _getStudentSessionsUseCase = getStudentSessionsUseCase,
       _applyForSessionUseCase = applyForSessionUseCase,
       _cancelApplicationUseCase = cancelApplicationUseCase {
    _subscribeToLogoutEvents();
  }

  // State
  bool _isLoading = false;
  AppError? _error;
  List<StudentSessionApplication> _applications = [];
  List<Timeslot> _availableTimeslots = [];

  // Stream subscription for logout events
  StreamSubscription? _logoutSubscription;

  // Getters
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  List<StudentSessionApplication> get applications => _applications;
  List<Timeslot> get availableTimeslots => _availableTimeslots;

  /// Load student session applications
  Future<bool> loadStudentSessions() async {
    _setLoading(true);
    _clearError();

    final result = await _getStudentSessionsUseCase.call();

    result.when(
      success: (applications) {
        _applications = applications;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Apply for a student session
  Future<bool> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
  }) async {
    _setLoading(true);
    _clearError();

    final params = ApplyForSessionParams(
      companyId: companyId,
      motivationText: motivationText,
      programme: programme,
      linkedin: linkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
    );

    final result = await _applyForSessionUseCase.call(params);

    result.when(
      success: (application) {
        // Add to local list
        _applications.add(application);
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Cancel a student session application
  Future<bool> cancelApplication(int companyId) async {
    _setLoading(true);
    _clearError();

    final result = await _cancelApplicationUseCase.call(companyId);

    result.when(
      success: (_) {
        // Remove from local list
        _applications.removeWhere((app) => app.companyId == companyId);
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Refresh student sessions
  Future<void> refreshStudentSessions() async {
    await loadStudentSessions();
  }

  /// Load timeslots for a company (temporary method for legacy compatibility)
  Future<bool> loadTimeslots(int companyId) async {
    // For now, return empty list - this screen needs proper clean architecture implementation
    _availableTimeslots = [];
    return true;
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(AppError? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// Subscribe to logout events for cleanup
  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _handleUserLogout();
    });
  }

  /// Handle user logout by clearing all session data
  void _handleUserLogout() {
    _isLoading = false;
    _error = null;
    _applications.clear();
    _availableTimeslots.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _logoutSubscription?.cancel();
    super.dispose();
  }
}
