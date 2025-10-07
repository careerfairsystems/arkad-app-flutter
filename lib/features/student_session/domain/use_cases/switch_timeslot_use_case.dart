import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../repositories/student_session_repository.dart';

/// Parameters for switching timeslot
class SwitchTimeslotParams {
  const SwitchTimeslotParams({
    required this.fromTimeslotId,
    required this.newTimeslotId,
  });

  final int fromTimeslotId;
  final int newTimeslotId;

  /// Validate params
  bool get isValid =>
      fromTimeslotId > 0 &&
      newTimeslotId > 0 &&
      fromTimeslotId != newTimeslotId;
}

/// Use case for switching from current booked timeslot to a new timeslot
/// atomically to prevent race conditions
class SwitchTimeslotUseCase implements UseCase<String, SwitchTimeslotParams> {
  const SwitchTimeslotUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(SwitchTimeslotParams params) async {
    // Validate params
    if (params.fromTimeslotId <= 0) {
      return Result.failure(
        const StudentSessionApplicationError(
          'Invalid timeslot selection',
          details: 'Current timeslot ID is invalid. Please try again.',
        ),
      );
    }

    if (params.newTimeslotId <= 0) {
      return Result.failure(
        const StudentSessionApplicationError(
          'Invalid timeslot selection',
          details:
              'New timeslot ID is invalid. Please select a valid timeslot.',
        ),
      );
    }

    if (params.fromTimeslotId == params.newTimeslotId) {
      return Result.failure(
        const StudentSessionApplicationError(
          'Same timeslot selected',
          details:
              'You have selected the same timeslot. Please choose a different time.',
        ),
      );
    }

    // Call repository for atomic switch
    return _repository.switchTimeslot(
      fromTimeslotId: params.fromTimeslotId,
      newTimeslotId: params.newTimeslotId,
    );
  }
}
