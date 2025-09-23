import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/student_session.dart';
import '../entities/student_session_application.dart';
import '../entities/timeslot.dart';
import '../repositories/student_session_repository.dart';

/// Unified service for student session data operations
/// Consolidates all student session data retrieval into a single source of truth
class StudentSessionDataService {
  const StudentSessionDataService({
    required StudentSessionRepository repository,
  }) : _repository = repository;

  final StudentSessionRepository _repository;

  /// Get all student sessions with their current application states
  /// This is the single source of truth for student session data
  Future<Result<List<StudentSessionWithApplicationState>>> getStudentSessionsWithApplicationState() async {
    try {
      // Get base student sessions
      final sessionsResult = await _repository.getStudentSessions();
      final sessions = sessionsResult.when(
        success: (data) => data,
        failure: (error) => throw error,
      );

      // Get applications with booking state for authenticated users
      final applicationsResult = await _repository.getMyApplicationsWithBookingState();
      final applications = applicationsResult.when(
        success: (data) => data,
        failure: (_) => <StudentSessionApplicationWithBookingState>[], // Graceful fallback for unauthenticated users
      );

      // Create unified data structure
      final unifiedData = <StudentSessionWithApplicationState>[];

      for (final session in sessions) {
        // Find matching application for this session
        final matchingApplication = applications
            .where((app) => app.application.companyId == session.companyId)
            .firstOrNull;

        unifiedData.add(StudentSessionWithApplicationState(
          session: session,
          applicationWithBookingState: matchingApplication,
        ));
      }

      return Result.success(unifiedData);
    } catch (e) {
      return Result.failure(e as AppError);
    }
  }

  /// Get applications with booking state only (for profile view)
  /// This delegates to the repository but ensures consistent error handling
  Future<Result<List<StudentSessionApplicationWithBookingState>>> getMyApplicationsWithBookingState({
    bool forceRefresh = false,
  }) async {
    return await _repository.getMyApplicationsWithBookingState();
  }

  /// Get timeslots for a specific company
  Future<Result<List<Timeslot>>> getTimeslots(int companyId) async {
    return await _repository.getTimeslots(companyId);
  }
}

/// Unified entity that combines session data with application state
/// This provides a single source of truth for session + application data
class StudentSessionWithApplicationState {
  const StudentSessionWithApplicationState({
    required this.session,
    this.applicationWithBookingState,
  });

  /// The base student session
  final StudentSession session;

  /// The application with booking state (null if no application)
  final StudentSessionApplicationWithBookingState? applicationWithBookingState;

  /// Get the effective application status for this session
  /// This is the authoritative status that should be displayed
  ApplicationStatus? get effectiveApplicationStatus {
    // Priority 1: Use application status if available (most accurate)
    if (applicationWithBookingState != null) {
      return applicationWithBookingState!.application.status;
    }

    // Priority 2: Convert session userStatus to ApplicationStatus
    if (session.userStatus != null) {
      switch (session.userStatus!) {
        case StudentSessionStatus.pending:
          return ApplicationStatus.pending;
        case StudentSessionStatus.accepted:
          return ApplicationStatus.accepted;
        case StudentSessionStatus.rejected:
          return ApplicationStatus.rejected;
      }
    }

    // Priority 3: No application exists
    return null;
  }

  /// Check if user has applied to this session
  bool get hasApplication => effectiveApplicationStatus != null;

  /// Check if user can apply to this session
  bool get canApply => session.isAvailable && !hasApplication;

  /// Check if user can book timeslots for this session
  bool get canBook => effectiveApplicationStatus == ApplicationStatus.accepted;

  /// Check if user has a booking for this session
  bool get hasBooking => applicationWithBookingState?.hasBooking ?? false;

  /// Get the booked timeslot (if any)
  Timeslot? get bookedTimeslot => applicationWithBookingState?.bookedTimeslot;

  @override
  String toString() {
    return 'StudentSessionWithApplicationState(session: ${session.companyName}, applicationStatus: $effectiveApplicationStatus, hasBooking: $hasBooking)';
  }
}