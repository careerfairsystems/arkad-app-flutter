import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/student_session.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting a specific student session by session ID
class GetStudentSessionByIdUseCase extends UseCase<StudentSession?, int> {
  const GetStudentSessionByIdUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<StudentSession?>> call(int sessionId) async {
    if (sessionId <= 0) {
      return Result.failure(
        ValidationError('Session ID must be greater than 0'),
      );
    }

    return await _repository.getStudentSessionById(sessionId);
  }
}
