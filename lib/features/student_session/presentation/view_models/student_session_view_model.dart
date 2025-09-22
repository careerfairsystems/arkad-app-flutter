import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../shared/errors/student_session_errors.dart';
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
import '../commands/get_my_applications_with_booking_state_command.dart';
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
  final GetMyApplicationsWithBookingStateCommand _getMyApplicationsWithBookingStateCommand;
  final GetTimeslotsCommand _getTimeslotsCommand;
  final UploadCVUseCase _uploadCVUseCase;
  final AuthViewModel _authViewModel;

  StudentSessionViewModel({
    required GetStudentSessionsCommand getStudentSessionsCommand,
    required ApplyForSessionCommand applyForSessionCommand,
    required BookTimeslotCommand bookTimeslotCommand,
    required UnbookTimeslotCommand unbookTimeslotCommand,
    required GetMyApplicationsCommand getMyApplicationsCommand,
    required GetMyApplicationsWithBookingStateCommand getMyApplicationsWithBookingStateCommand,
    required GetTimeslotsCommand getTimeslotsCommand,
    required UploadCVUseCase uploadCVUseCase,
    required AuthViewModel authViewModel,
  }) : _getStudentSessionsCommand = getStudentSessionsCommand,
       _applyForSessionCommand = applyForSessionCommand,
       _bookTimeslotCommand = bookTimeslotCommand,
       _unbookTimeslotCommand = unbookTimeslotCommand,
       _getMyApplicationsCommand = getMyApplicationsCommand,
       _getMyApplicationsWithBookingStateCommand = getMyApplicationsWithBookingStateCommand,
       _getTimeslotsCommand = getTimeslotsCommand,
       _uploadCVUseCase = uploadCVUseCase,
       _authViewModel = authViewModel {
    _setupCommandListeners();
    _subscribeToLogoutEvents();
  }

  // UI state
  String _searchQuery = '';
  int? _selectedCompanyId;
  
  // CV upload error state (when CV upload fails after successful application)
  StudentSessionApplicationError? _cvUploadError;
  
  // Message display flags to prevent duplicates
  bool _showSuccessMessage = false;
  String? _successMessage;
  bool _showErrorMessage = false;
  String? _errorMessage;

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
  GetMyApplicationsWithBookingStateCommand get getMyApplicationsWithBookingStateCommand =>
      _getMyApplicationsWithBookingStateCommand;
  GetTimeslotsCommand get getTimeslotsCommand => _getTimeslotsCommand;

  // Computed state from commands
  List<StudentSession> get studentSessions {
    final sessions = _getStudentSessionsCommand.result ?? [];
    
    // If user is not authenticated, clear user status to show public view
    if (!_authViewModel.isAuthenticated) {
      return sessions.map((session) => StudentSession(
        id: session.id,
        companyId: session.companyId,
        companyName: session.companyName,
        isAvailable: session.isAvailable,
        bookingCloseTime: session.bookingCloseTime,
        userStatus: null, // Clear user status for public view
        logoUrl: session.logoUrl,
        description: session.description,
      )).toList();
    }
    
    return sessions;
  }
  List<StudentSessionApplication> get myApplications =>
      _getMyApplicationsCommand.result ?? [];
  List<StudentSessionApplicationWithBookingState> get myApplicationsWithBookingState =>
      _getMyApplicationsWithBookingStateCommand.result ?? [];
  List<Timeslot> get timeslots => _getTimeslotsCommand.result ?? [];

  // UI state getters
  String get searchQuery => _searchQuery;
  int? get selectedCompanyId => _selectedCompanyId;
  
  // CV upload error getter
  StudentSessionApplicationError? get cvUploadError => _cvUploadError;
  
  // Message display getters
  bool get showSuccessMessage => _showSuccessMessage;
  String? get successMessage => _successMessage;
  bool get showErrorMessage => _showErrorMessage;
  String? get errorMessage => _errorMessage;

  // Computed getters
  bool get isLoading =>
      _getStudentSessionsCommand.isExecuting ||
      _applyForSessionCommand.isExecuting ||
      _bookTimeslotCommand.isExecuting ||
      _unbookTimeslotCommand.isExecuting ||
      _getMyApplicationsCommand.isExecuting ||
      _getMyApplicationsWithBookingStateCommand.isExecuting ||
      _getTimeslotsCommand.isExecuting;

  bool get hasError =>
      _getStudentSessionsCommand.hasError ||
      _applyForSessionCommand.hasError ||
      _bookTimeslotCommand.hasError ||
      _unbookTimeslotCommand.hasError ||
      _getMyApplicationsCommand.hasError ||
      _getMyApplicationsWithBookingStateCommand.hasError ||
      _getTimeslotsCommand.hasError ||
      _cvUploadError != null;

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

  // Enhanced getters with real booking state
  List<StudentSessionApplicationWithBookingState> get pendingApplicationsWithBookingState =>
      myApplicationsWithBookingState
          .where((app) => app.application.status == ApplicationStatus.pending)
          .toList();

  List<StudentSessionApplicationWithBookingState> get acceptedApplicationsWithBookingState =>
      myApplicationsWithBookingState
          .where((app) => app.application.status == ApplicationStatus.accepted)
          .toList();

  List<StudentSessionApplicationWithBookingState> get rejectedApplicationsWithBookingState =>
      myApplicationsWithBookingState
          .where((app) => app.application.status == ApplicationStatus.rejected)
          .toList();

  // Booking-specific getters using real API data
  List<StudentSessionApplicationWithBookingState> get bookableApplications =>
      myApplicationsWithBookingState.where((app) => app.canBook).toList();

  List<StudentSessionApplicationWithBookingState> get bookedApplications =>
      myApplicationsWithBookingState.where((app) => app.hasBooking).toList();

  List<StudentSessionApplicationWithBookingState> get cancellableApplications =>
      myApplicationsWithBookingState.where((app) => app.canCancelBooking).toList();

  /// Load student sessions with optional force refresh
  Future<void> loadStudentSessions({bool forceRefresh = false}) async {
    await _getStudentSessionsCommand.loadStudentSessions(
      forceRefresh: forceRefresh,
    );
  }

  /// Wait for authentication to complete with timeout protection
  /// Returns true if user is authenticated, false if timeout or not authenticated
  Future<bool> _waitForAuthCompletion() async {
    try {
      // Wait for auth initialization to complete with 5-second timeout
      await _authViewModel.waitForInitialization.timeout(
        const Duration(seconds: 5),
      );
      return _authViewModel.isAuthenticated;
    } catch (e) {
      // Timeout or other error - return false for graceful fallback
      return false;
    }
  }

  /// Load my applications
  Future<void> loadMyApplications({bool forceRefresh = false}) async {
    // Wait for authentication completion with timeout protection
    if (!await _waitForAuthCompletion()) {
      return; // Don't load applications if user is not authenticated or timeout occurred
    }

    await _getMyApplicationsCommand.loadMyApplications(
      forceRefresh: forceRefresh,
    );
  }

  /// Load my applications with real booking state from timeslots
  /// This provides accurate booking information by checking API timeslot status
  Future<void> loadMyApplicationsWithBookingState({bool forceRefresh = false}) async {
    // Wait for authentication completion with timeout protection
    if (!await _waitForAuthCompletion()) {
      return; // Don't load applications if user is not authenticated or timeout occurred
    }

    await _getMyApplicationsWithBookingStateCommand.loadMyApplicationsWithBookingState(
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
  /// Returns true if upload was successful, false otherwise
  /// Stores detailed error information for UI recovery options
  Future<bool> uploadCVForSession({
    required int companyId,
    required String filePath,
  }) async {
    try {
      final result = await _uploadCVUseCase.call(
        UploadCVParams(companyId: companyId, filePath: filePath),
      );
      return result.when(
        success: (_) {
          // Clear any previous CV upload errors on success
          _cvUploadError = null;
          return true;
        },
        failure: (error) {
          // Log for debugging - don't set UI error here as it's handled by calling methods
          print('CV upload failed for company $companyId: ${error.userMessage}');
          return false;
        },
      );
    } catch (e) {
      // Log unexpected errors - don't set UI error here as it's handled by calling methods
      print('Unexpected error during CV upload for company $companyId: $e');
      return false;
    }
  }

  /// Apply for a student session with optional CV upload
  /// Profile is always updated with application data by the backend
  /// If CV is provided, CV upload failure will block the entire application
  Future<void> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    String? cvFilePath,
  }) async {
    // Clear any previous messages and errors
    clearAllMessages();
    _cvUploadError = null;
    
    // First, apply for the session to create the StudentSessionApplication record
    await _applyForSessionCommand.applyForSession(
      companyId: companyId,
      motivationText: motivationText,
      programme: programme,
      linkedin: linkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
    );
    
    // Check if application submission failed
    if (_applyForSessionCommand.hasError) {
      final error = _applyForSessionCommand.error;
      _setErrorMessage(error?.userMessage ?? 'Failed to submit application. Please try again.');
      return;
    }
    
    // Only proceed with CV upload if application was successful
    if (_applyForSessionCommand.isCompleted && 
        !_applyForSessionCommand.hasError) {
      
      // Backend always updates user profile with application data, so refresh session
      await _authViewModel.refreshSession();
      
      // If CV file is provided, upload it after successful application
      // CV upload failure is now BLOCKING - it will fail the entire application
      if (cvFilePath != null && cvFilePath.isNotEmpty) {
        final cvUploaded = await uploadCVForSession(
          companyId: companyId,
          filePath: cvFilePath,
        );
        
        if (!cvUploaded) {
          // CV upload failed - this is now a blocking error
          // Note: The application record exists in the backend but without CV attachment
          // This approach allows users to retry CV upload without re-submitting application data
          _setErrorMessage('Application failed: Could not upload your CV. Please check your file and try again.');
          print('Application failed for company $companyId due to CV upload failure - application data preserved for retry');
          return;
        }
        
        // Both application and CV upload succeeded
        _setSuccessMessage('Application with CV submitted successfully!');
      } else {
        // Application succeeded without CV
        _setSuccessMessage('Application submitted successfully!');
      }
      
      print('Application and CV upload successful for company $companyId');
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
  
  /// Clear CV upload error
  void clearCVUploadError() {
    _cvUploadError = null;
    notifyListeners();
  }
  
  /// Set success message for display
  void _setSuccessMessage(String message) {
    _showSuccessMessage = true;
    _successMessage = message;
    notifyListeners();
  }
  
  /// Set error message for display
  void _setErrorMessage(String message) {
    _showErrorMessage = true;
    _errorMessage = message;
    notifyListeners();
  }
  
  /// Clear success message after display
  void clearSuccessMessage() {
    _showSuccessMessage = false;
    _successMessage = null;
    notifyListeners();
  }
  
  /// Clear error message after display
  void clearErrorMessage() {
    _showErrorMessage = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Clear all message flags
  void clearAllMessages() {
    _showSuccessMessage = false;
    _successMessage = null;
    _showErrorMessage = false;
    _errorMessage = null;
    notifyListeners();
  }
  
  /// Retry CV upload for a previously failed application
  /// This allows users to retry CV upload without re-submitting the entire application
  Future<bool> retryCVUpload({
    required int companyId,
    required String filePath,
  }) async {
    // Clear previous messages and errors before retry
    clearAllMessages();
    _cvUploadError = null;
    
    final success = await uploadCVForSession(
      companyId: companyId,
      filePath: filePath,
    );
    
    if (success) {
      _setSuccessMessage('CV uploaded successfully! Application is now complete.');
    } else {
      _setErrorMessage('CV upload failed. Please check your file and try again.');
    }
    
    return success;
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
    _bookTimeslotCommand.addListener(_onBookTimeslotCommandChanged);
    _unbookTimeslotCommand.addListener(_onUnbookTimeslotCommandChanged);
    _getMyApplicationsCommand.addListener(_onCommandStateChanged);
    _getMyApplicationsWithBookingStateCommand.addListener(_onCommandStateChanged);
    _getTimeslotsCommand.addListener(_onCommandStateChanged);
  }

  /// Handle command state changes
  void _onCommandStateChanged() {
    // Simply propagate state changes without triggering chain reactions
    // Individual screens can handle their own data refresh needs
    notifyListeners();
  }

  /// Handle book timeslot command state changes
  void _onBookTimeslotCommandChanged() {
    if (_bookTimeslotCommand.isCompleted && !_bookTimeslotCommand.hasError) {
      _setSuccessMessage('Timeslot booked successfully!');
      // Refresh applications to get updated booking info
      loadMyApplicationsWithBookingState(forceRefresh: true);
    } else if (_bookTimeslotCommand.hasError) {
      final error = _bookTimeslotCommand.error;
      _setErrorMessage(error?.userMessage ?? 'Failed to book timeslot. Please try again.');
    }
    notifyListeners();
  }

  /// Handle unbook timeslot command state changes
  void _onUnbookTimeslotCommandChanged() {
    if (_unbookTimeslotCommand.isCompleted && !_unbookTimeslotCommand.hasError) {
      _setSuccessMessage('Booking cancelled successfully!');
      // Refresh applications to get updated booking info
      loadMyApplicationsWithBookingState(forceRefresh: true);
    } else if (_unbookTimeslotCommand.hasError) {
      final error = _unbookTimeslotCommand.error;
      _setErrorMessage(error?.userMessage ?? 'Failed to cancel booking. Please try again.');
    }
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
    _cvUploadError = null;
    
    // Clear all message flags
    clearAllMessages();

    // Reset all commands
    _getStudentSessionsCommand.reset();
    _applyForSessionCommand.reset();
    _bookTimeslotCommand.reset();
    _unbookTimeslotCommand.reset();
    _getMyApplicationsCommand.reset();
    _getMyApplicationsWithBookingStateCommand.reset();
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
    _bookTimeslotCommand.removeListener(_onBookTimeslotCommandChanged);
    _unbookTimeslotCommand.removeListener(_onUnbookTimeslotCommandChanged);
    _getMyApplicationsCommand.removeListener(_onCommandStateChanged);
    _getMyApplicationsWithBookingStateCommand.removeListener(_onCommandStateChanged);
    _getTimeslotsCommand.removeListener(_onCommandStateChanged);

    super.dispose();
  }
}
