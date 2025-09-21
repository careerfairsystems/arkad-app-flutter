import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../entities/timeslot.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting available timeslots for a company
/// Only available to students who have been accepted for that company's student session
class GetTimeslotsUseCase extends UseCase<List<Timeslot>, int> {
  const GetTimeslotsUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<List<Timeslot>>> call(int companyId) async {
    try {
      // Validate booking timeline - timeslots should only be visible during booking period
      TimelineValidationService.validateBookingAllowed();

      // Get timeslots from repository
      final result = await _repository.getTimeslots(companyId);

      return result.when(
        success: (timeslots) {
          // Return all timeslots - let UI decide what to display
          // This includes both free and bookedByCurrentUser timeslots for booking management
          return Result.success(timeslots);
        },
        failure: (error) => Result.failure(error),
      );
    } on StudentSessionTimelineError catch (e) {
      return Result.failure(e);
    } catch (e) {
      return Result.failure(
        StudentSessionApplicationError(
          'Failed to load timeslots',
          details: e.toString(),
        ),
      );
    }
  }
}
