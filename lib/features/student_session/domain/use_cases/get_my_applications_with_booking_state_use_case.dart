import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/student_session_application.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting user's student session applications with real booking state
/// This provides accurate booking information by checking timeslot status from API
class GetMyApplicationsWithBookingStateUseCase
    extends NoParamsUseCase<List<StudentSessionApplicationWithBookingState>> {
  const GetMyApplicationsWithBookingStateUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<List<StudentSessionApplicationWithBookingState>>> call() async {
    return _repository.getMyApplicationsWithBookingState();
  }
}