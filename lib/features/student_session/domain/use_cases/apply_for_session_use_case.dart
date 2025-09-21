import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../entities/student_session.dart';
import '../repositories/student_session_repository.dart';

/// Use case for applying to a student session with timeline validation
class ApplyForSessionUseCase
    extends UseCase<String, StudentSessionApplicationParams> {
  const ApplyForSessionUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(StudentSessionApplicationParams params) async {
    try {
      // Validate application timeline
      TimelineValidationService.validateApplicationAllowed();

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

      // Submit application through repository
      return await _repository.applyForSession(params);
    } on StudentSessionTimelineError catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        StudentSessionApplicationError(
          'Failed to submit application',
          details: e.toString(),
        ),
      );
    }
  }
}
