import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../repositories/profile_repository.dart';

/// Use case for deleting user CV document
class DeleteCVUseCase extends UseCase<void, NoParams> {
  const DeleteCVUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<void>> call([NoParams? params]) async {
    return await _repository.deleteCV();
  }
}