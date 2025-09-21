import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../repositories/student_session_repository.dart';

/// Parameters for booking a timeslot
class BookTimeslotParams {
  const BookTimeslotParams({required this.companyId, required this.timeslotId});

  final int companyId;
  final int timeslotId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookTimeslotParams &&
        other.companyId == companyId &&
        other.timeslotId == timeslotId;
  }

  @override
  int get hashCode => Object.hash(companyId, timeslotId);

  @override
  String toString() =>
      'BookTimeslotParams(companyId: $companyId, timeslotId: $timeslotId)';
}

/// Use case for booking a specific timeslot
/// Includes timeline validation and conflict handling
class BookTimeslotUseCase extends UseCase<String, BookTimeslotParams> {
  const BookTimeslotUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(BookTimeslotParams params) async {
    try {
      // Validate booking timeline
      TimelineValidationService.validateBookingAllowed();

      // Validate parameters
      if (params.companyId <= 0 || params.timeslotId <= 0) {
        return Result.failure(
          const StudentSessionApplicationError(
            'Invalid booking parameters. Please try again.',
          ),
        );
      }

      // Attempt to book the timeslot
      final result = await _repository.bookTimeslot(
        companyId: params.companyId,
        timeslotId: params.timeslotId,
      );

      return result;
    } on StudentSessionTimelineError catch (e) {
      return Result.failure(e);
    } catch (e) {
      // Check if it's a conflict error (slot taken)
      if (e.toString().contains('conflict') ||
          e.toString().contains('already booked') ||
          e.toString().contains('409')) {
        return Result.failure(
          StudentSessionBookingConflictError(
            'This timeslot was just booked by someone else. Please select another time.',
          ),
        );
      }

      return Result.failure(
        StudentSessionApplicationError(
          'Failed to book timeslot',
          details: e.toString(),
        ),
      );
    }
  }
}
