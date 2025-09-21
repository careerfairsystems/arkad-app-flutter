import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/student_session_application.dart';
import '../repositories/student_session_repository.dart';

/// Use case for getting user's student session applications (for profile screen)
class GetMyApplicationsUseCase
    extends NoParamsUseCase<List<StudentSessionApplication>> {
  const GetMyApplicationsUseCase(this._repository);

  final StudentSessionRepository _repository;

  @override
  Future<Result<List<StudentSessionApplication>>> call() async {
    return _repository.getMyApplications();
  }
}
