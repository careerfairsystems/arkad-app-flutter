import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/student_session_application.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting all student session applications
class GetStudentSessionsUseCase extends NoParamsUseCase<List<StudentSessionApplication>> {
  final StudentSessionRepository _repository;

  GetStudentSessionsUseCase(this._repository);

  @override
  Future<Result<List<StudentSessionApplication>>> call() {
    return _repository.getStudentSessions();
  }
}