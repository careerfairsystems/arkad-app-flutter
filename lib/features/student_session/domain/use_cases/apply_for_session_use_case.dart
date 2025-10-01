import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../entities/student_session.dart';
import '../repositories/student_session_repository.dart';

/// Use case for applying to a student session
class ApplyForSessionUseCase
    extends UseCase<String, StudentSessionApplicationParams> {
  const ApplyForSessionUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(StudentSessionApplicationParams params) async {
    try {
      // Validate application parameters
      if (!params.isValid) {
        return Result.failure(
          const StudentSessionApplicationError(
            'Invalid application data. Please check all required fields.',
          ),
        );
      }

      // Check motivation text length
      if (!params.isMotivationValid) {
        return Result.failure(
          StudentSessionApplicationError(
            'Motivation text must be 300 words or less. Currently ${params.motivationWordCount} words.',
          ),
        );
      }

      // Submit application through repository - session availability controlled by server data
      return await _repository.applyForSession(params);
    } catch (e) {
      return Result.failure(
        const StudentSessionApplicationError(
          'Failed to submit application',
          details: 'An unexpected error occurred',
        ),
      );
    }
  }
}
