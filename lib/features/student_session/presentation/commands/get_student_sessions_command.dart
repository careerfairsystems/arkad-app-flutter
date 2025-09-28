import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/use_cases/get_student_sessions_use_case.dart';

/// Command for loading student sessions with defensive pattern implementation
class GetStudentSessionsCommand extends Command<List<StudentSession>> {
  GetStudentSessionsCommand(this._getStudentSessionsUseCase);

  final GetStudentSessionsUseCase _getStudentSessionsUseCase;

  /// Load student sessions with comprehensive error handling
  Future<void> loadStudentSessions() async {
    return execute();
  }

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      // Execute the use case
      final result = await _getStudentSessionsUseCase.call();

      result.when(
        success: (sessions) {
          // Validate the received data
          final validatedSessions = _validateAndFilterSessions(sessions);
          setResult(validatedSessions);
        },
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        const StudentSessionApplicationError(
          'Failed to load student sessions',
          details: 'Unable to load student sessions. Please try again.',
        ),
      );
    } finally {
      setExecuting(false);
    }
  }

  /// Validates and filters the student sessions data
  List<StudentSession> _validateAndFilterSessions(
    List<StudentSession> sessions,
  ) {
    // Filter out any sessions with invalid data
    final validSessions =
        sessions.where((session) {
          // Basic validation: must have valid ID and company ID
          if (session.id <= 0 || session.companyId <= 0) {
            return false;
          }

          // Must have a booking close time if user has applied/been accepted
          if (session.userStatus != null && session.bookingCloseTime == null) {
            return false;
          }

          return true;
        }).toList();

    // Sort sessions: available first, then by company name
    validSessions.sort((a, b) {
      // Available sessions first
      if (a.isAvailable && !b.isAvailable) return -1;
      if (!a.isAvailable && b.isAvailable) return 1;

      // Then by company name (alphabetical)
      return a.companyName.compareTo(b.companyName);
    });

    return validSessions;
  }

  /// Check if we have any sessions loaded
  bool get hasSessions => result?.isNotEmpty == true;

  /// Get count of available sessions
  int get availableSessionsCount =>
      result?.where((session) => session.isAvailable).length ?? 0;

  /// Get sessions that user has applied to
  List<StudentSession> get appliedSessions =>
      result?.where((session) => session.userStatus != null).toList() ?? [];

  /// Get sessions that are available for application
  List<StudentSession> get availableSessions =>
      result
          ?.where(
            (session) => session.isAvailable && session.userStatus == null,
          )
          .toList() ??
      [];

  /// Reset command state and clear any errors
  @override
  void reset({bool notify = true}) {
    super.reset(notify: notify);
  }
}
