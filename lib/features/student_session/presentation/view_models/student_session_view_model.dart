import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/use_cases/upload_cv_use_case.dart';
import '../commands/apply_for_session_command.dart';
import '../commands/book_timeslot_command.dart';
import '../commands/get_my_applications_command.dart';
import '../commands/get_student_sessions_command.dart';
import '../commands/get_timeslots_command.dart';
import '../commands/unbook_timeslot_command.dart';

/// ViewModel for coordinating student session commands and managing UI state
class StudentSessionViewModel extends ChangeNotifier {
  final GetStudentSessionsCommand _getStudentSessionsCommand;
  final ApplyForSessionCommand _applyForSessionCommand;
  final BookTimeslotCommand _bookTimeslotCommand;
  final UnbookTimeslotCommand _unbookTimeslotCommand;
  final GetMyApplicationsCommand _getMyApplicationsCommand;
  final GetTimeslotsCommand _getTimeslotsCommand;
  final UploadCVUseCase _uploadCVUseCase;
  final AuthViewModel _authViewModel;

  StudentSessionViewModel({
    required GetStudentSessionsCommand getStudentSessionsCommand,
    required ApplyForSessionCommand applyForSessionCommand,
    required BookTimeslotCommand bookTimeslotCommand,
    required UnbookTimeslotCommand unbookTimeslotCommand,
    required GetMyApplicationsCommand getMyApplicationsCommand,
    required GetTimeslotsCommand getTimeslotsCommand,
    required UploadCVUseCase uploadCVUseCase,
    required AuthViewModel authViewModel,
  }) : _getStudentSessionsCommand = getStudentSessionsCommand,
       _applyForSessionCommand = applyForSessionCommand,
       _bookTimeslotCommand = bookTimeslotCommand,
       _unbookTimeslotCommand = unbookTimeslotCommand,
       _getMyApplicationsCommand = getMyApplicationsCommand,
       _getTimeslotsCommand = getTimeslotsCommand,
       _uploadCVUseCase = uploadCVUseCase,
       _authViewModel = authViewModel {
    _setupCommandListeners();
    _subscribeToLogoutEvents();
  }

  // UI state
  String _searchQuery = '';
  int? _selectedCompanyId;

  // Stream subscription for logout events
  StreamSubscription? _logoutSubscription;

  // Command getters for UI access
  GetStudentSessionsCommand get getStudentSessionsCommand =>
      _getStudentSessionsCommand;
  ApplyForSessionCommand get applyForSessionCommand => _applyForSessionCommand;
  BookTimeslotCommand get bookTimeslotCommand => _bookTimeslotCommand;
  UnbookTimeslotCommand get unbookTimeslotCommand => _unbookTimeslotCommand;
  GetMyApplicationsCommand get getMyApplicationsCommand =>
      _getMyApplicationsCommand;
  GetTimeslotsCommand get getTimeslotsCommand => _getTimeslotsCommand;

  // Computed state from commands
  List<StudentSession> get studentSessions =>
      _getStudentSessionsCommand.result ?? [];
  List<StudentSessionApplication> get myApplications =>
      _getMyApplicationsCommand.result ?? [];
  List<Timeslot> get timeslots => _getTimeslotsCommand.result ?? [];

  // UI state getters
  String get searchQuery => _searchQuery;
  int? get selectedCompanyId => _selectedCompanyId;

  // Computed getters
  bool get isLoading =>
      _getStudentSessionsCommand.isExecuting ||
      _applyForSessionCommand.isExecuting ||
      _bookTimeslotCommand.isExecuting ||
      _unbookTimeslotCommand.isExecuting ||
      _getMyApplicationsCommand.isExecuting ||
      _getTimeslotsCommand.isExecuting;

  bool get hasError =>
      _getStudentSessionsCommand.hasError ||
      _applyForSessionCommand.hasError ||
      _bookTimeslotCommand.hasError ||
      _unbookTimeslotCommand.hasError ||
      _getMyApplicationsCommand.hasError ||
      _getTimeslotsCommand.hasError;

  // Filtered student sessions based on search
  List<StudentSession> get filteredStudentSessions {
    if (_searchQuery.isEmpty) return studentSessions;

    return studentSessions.where((session) {
      return session.companyName.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
    }).toList();
  }

  // Get applications by status
  List<StudentSessionApplication> get pendingApplications =>
      myApplications
          .where((app) => app.status == ApplicationStatus.pending)
          .toList();

  List<StudentSessionApplication> get acceptedApplications =>
      myApplications
          .where((app) => app.status == ApplicationStatus.accepted)
          .toList();

  List<StudentSessionApplication> get rejectedApplications =>
      myApplications
          .where((app) => app.status == ApplicationStatus.rejected)
          .toList();

  /// Load student sessions with optional force refresh
  Future<void> loadStudentSessions({bool forceRefresh = false}) async {
    await _getStudentSessionsCommand.loadStudentSessions(
      forceRefresh: forceRefresh,
    );
  }

  /// Load my applications
  Future<void> loadMyApplications({bool forceRefresh = false}) async {
    // Ensure authentication is ready before making API calls
    if (!_authViewModel.isAuthenticated || _authViewModel.isInitializing) {
      // Wait for authentication to complete if still initializing
      if (_authViewModel.isInitializing) {
        // Poll until auth initialization is complete
        while (_authViewModel.isInitializing) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }
      
      // Check again after waiting
      if (!_authViewModel.isAuthenticated) {
        return; // Don't load applications if user is not authenticated
      }
    }

    await _getMyApplicationsCommand.loadMyApplications(
      forceRefresh: forceRefresh,
    );
  }

  /// Load timeslots for a company
  Future<void> loadTimeslots(int companyId, {bool forceRefresh = false}) async {
    await _getTimeslotsCommand.loadTimeslots(
      companyId,
      forceRefresh: forceRefresh,
    );
  }

  /// Upload CV for a student session
  Future<bool> uploadCVForSession({
    required int companyId,
    required String filePath,
  }) async {
    try {
      final result = await _uploadCVUseCase.call(
        UploadCVParams(companyId: companyId, filePath: filePath),
      );
      return result.when(
        success: (_) => true,
        failure: (_) => false,
      );
    } catch (e) {
      return false;
    }
  }

  /// Apply for a student session with optional CV upload
  /// Profile is always updated with application data by the backend
  Future<void> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    String? cvFilePath,
  }) async {
    // If CV file is provided, upload it first
    if (cvFilePath != null && cvFilePath.isNotEmpty) {
      final cvUploaded = await uploadCVForSession(
        companyId: companyId,
        filePath: cvFilePath,
      );
      
      if (!cvUploaded) {
        // CV upload failed, don't proceed with application
        return;
      }
    }
    
    await _applyForSessionCommand.applyForSession(
      companyId: companyId,
      motivationText: motivationText,
      programme: programme,
      linkedin: linkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
    );
    
    // Backend always updates user profile with application data, so refresh session
    if (_applyForSessionCommand.isCompleted && 
        !_applyForSessionCommand.hasError) {
      await _authViewModel.refreshSession();
    }
  }

  /// Book a timeslot
  Future<void> bookTimeslot({
    required int companyId,
    required int timeslotId,
  }) async {
    await _bookTimeslotCommand.bookTimeslot(
      companyId: companyId,
      timeslotId: timeslotId,
    );
  }

  /// Unbook a timeslot
  Future<void> unbookTimeslot(int companyId) async {
    await _unbookTimeslotCommand.unbookTimeslot(companyId);
  }

  /// Search student sessions
  void searchStudentSessions(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Clear search
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Set selected company for timeslot operations
  void setSelectedCompany(int? companyId) {
    _selectedCompanyId = companyId;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await Future.wait([
      loadStudentSessions(forceRefresh: true),
      loadMyApplications(forceRefresh: true),
    ]);
  }

  /// Setup command listeners to propagate state changes
  void _setupCommandListeners() {
    _getStudentSessionsCommand.addListener(_onCommandStateChanged);
    _applyForSessionCommand.addListener(_onCommandStateChanged);
    _bookTimeslotCommand.addListener(_onCommandStateChanged);
    _unbookTimeslotCommand.addListener(_onCommandStateChanged);
    _getMyApplicationsCommand.addListener(_onCommandStateChanged);
    _getTimeslotsCommand.addListener(_onCommandStateChanged);
  }

  /// Handle command state changes
  void _onCommandStateChanged() {
    // Simply propagate state changes without triggering chain reactions
    // Individual screens can handle their own data refresh needs
    notifyListeners();
  }

  /// Subscribe to logout events for cleanup
  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _handleUserLogout();
    });
  }

  /// Handle user logout by clearing all session data and reloading public content
  void _handleUserLogout() {
    // Reset UI state
    _searchQuery = '';
    _selectedCompanyId = null;

    // Reset all commands
    _getStudentSessionsCommand.reset();
    _applyForSessionCommand.reset();
    _bookTimeslotCommand.reset();
    _unbookTimeslotCommand.reset();
    _getMyApplicationsCommand.reset();
    _getTimeslotsCommand.reset();

    // Immediately reload public student sessions (available without authentication)
    // This ensures users can still browse sessions when logged out
    loadStudentSessions();

    notifyListeners();
  }

  @override
  void dispose() {
    // Cancel event subscriptions
    _logoutSubscription?.cancel();

    // Remove command listeners
    _getStudentSessionsCommand.removeListener(_onCommandStateChanged);
    _applyForSessionCommand.removeListener(_onCommandStateChanged);
    _bookTimeslotCommand.removeListener(_onCommandStateChanged);
    _unbookTimeslotCommand.removeListener(_onCommandStateChanged);
    _getMyApplicationsCommand.removeListener(_onCommandStateChanged);
    _getTimeslotsCommand.removeListener(_onCommandStateChanged);

    super.dispose();
  }
}
