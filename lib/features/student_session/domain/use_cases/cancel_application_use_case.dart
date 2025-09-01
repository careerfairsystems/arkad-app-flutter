import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../repositories/student_session_repository.dart';

/// Use case for cancelling a student session application
class CancelApplicationUseCase extends UseCase<void, int> {
  final StudentSessionRepository _repository;

  CancelApplicationUseCase(this._repository);

  @override
  Future<Result<void>> call(int companyId) {
    return _repository.cancelApplication(companyId);
  }
}