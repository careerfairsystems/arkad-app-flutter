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
          // Filter to only show available timeslots
          final availableTimeslots =
              timeslots.where((timeslot) => timeslot.isAvailable).toList();

          return Result.success(availableTimeslots);
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
