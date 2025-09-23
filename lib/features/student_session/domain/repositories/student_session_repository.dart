import '../../../../shared/domain/result.dart';
import '../entities/student_session.dart';
import '../entities/student_session_application.dart';
import '../entities/timeslot.dart';

/// Repository interface for student session operations
abstract class StudentSessionRepository {
  /// Get all available student sessions with user's application status
  /// Maps from GET /api/student-session/all -> StudentSessionNormalUserListSchema
  Future<Result<List<StudentSession>>> getStudentSessions();

  /// Get a specific student session by company ID
  /// Maps from GET /api/student-session/all with filtering by company ID
  Future<Result<StudentSession?>> getStudentSessionById(int companyId);


  /// Get user's applications with enhanced booking state determined from timeslots
  /// This provides real booking status by checking timeslot status from the API
  Future<Result<List<StudentSessionApplicationWithBookingState>>> getMyApplicationsWithBookingState();

  /// Get available timeslots for a specific company (only if user is accepted)
  /// Maps from GET /api/student-session/timeslots -> List<TimeslotSchema>
  Future<Result<List<Timeslot>>> getTimeslots(int companyId);

  /// Apply for a student session with a company
  /// Maps to POST /api/student-session/apply -> StudentSessionApplicationSchema
  Future<Result<String>> applyForSession(
    StudentSessionApplicationParams params,
  );

  /// Upload CV for a specific company's student session
  /// Maps to POST /api/student-session/cv
  Future<Result<String>> uploadCVForSession({
    required int companyId,
    required String filePath,
  });

  /// Book a specific timeslot (only if user is accepted)
  /// Maps to POST /api/student-session/accept
  Future<Result<String>> bookTimeslot({
    required int companyId,
    required int timeslotId,
  });

  /// Unbook current timeslot for a company
  /// Maps to POST /api/student-session/unbook
  Future<Result<String>> unbookTimeslot(int companyId);

  /// Get application details for a specific company
  /// Maps to GET /api/student-session/application
  Future<Result<StudentSessionApplication?>> getApplicationForCompany(
    int companyId,
  );
}
