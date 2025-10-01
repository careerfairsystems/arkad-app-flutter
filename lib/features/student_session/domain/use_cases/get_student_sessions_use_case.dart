import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/student_session.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting all available student sessions
/// Returns list of StudentSession entities with user's application status
class GetStudentSessionsUseCase extends NoParamsUseCase<List<StudentSession>> {
  const GetStudentSessionsUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<List<StudentSession>>> call() async {
    // Fetch student sessions from repository
    return _repository.getStudentSessions();
  }
}
