import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../repositories/student_session_repository.dart';

/// Use case for unbooking a timeslot
class UnbookTimeslotUseCase extends UseCase<String, int> {
  const UnbookTimeslotUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(int companyId) async {
    try {
      // Validate booking timeline - unbooking should be allowed during booking period
      TimelineValidationService.validateBookingAllowed();

      // Validate parameters
      if (companyId <= 0) {
        return Result.failure(
          const StudentSessionApplicationError(
            'Invalid company ID. Please try again.',
          ),
        );
      }

      // Unbook the timeslot
      return await _repository.unbookTimeslot(companyId);
    } on StudentSessionTimelineError catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        StudentSessionApplicationError(
          'Failed to unbook timeslot',
          details: 'An unexpected error occurred',
        ),
      );
    }
  }
}
