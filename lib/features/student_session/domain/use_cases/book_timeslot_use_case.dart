import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/student_session_errors.dart';
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
/// Includes conflict handling
class BookTimeslotUseCase extends UseCase<String, BookTimeslotParams> {
  const BookTimeslotUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<String>> call(BookTimeslotParams params) async {
    try {
      // Validate parameters
      if (params.companyId <= 0 || params.timeslotId <= 0) {
        return Result.failure(
          const StudentSessionApplicationError(
            'Invalid booking parameters. Please try again.',
          ),
        );
      }

      // Attempt to book the timeslot - booking controlled by userStatus and bookingCloseTime
      // Repository handles conflict detection and typed error responses
      return await _repository.bookTimeslot(
        companyId: params.companyId,
        timeslotId: params.timeslotId,
      );
    } catch (e) {
      // Handle unexpected exceptions not caught by repository
      return Result.failure(
        StudentSessionApplicationError(
          'Failed to book timeslot',
          details: e.toString(),
        ),
      );
    }
  }
}
