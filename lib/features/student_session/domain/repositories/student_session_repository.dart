import '../../../../shared/domain/result.dart';
import '../entities/student_session_application.dart';
import '../entities/timeslot.dart';

/// Repository interface for student session operations
abstract class StudentSessionRepository {
  /// Get all student session applications for the current user
  Future<Result<List<StudentSessionApplication>>> getStudentSessions();

  /// Get available timeslots for a specific company
  Future<Result<List<Timeslot>>> getTimeslots(int companyId);

  /// Apply for a student session with a company
  Future<Result<StudentSessionApplication>> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
  });

  /// Cancel/unbook a student session application
  Future<Result<void>> cancelApplication(int companyId);

  /// Refresh cached student session data
  Future<Result<void>> refreshStudentSessions();
}
