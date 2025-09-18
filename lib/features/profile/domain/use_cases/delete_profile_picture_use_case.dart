import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../repositories/profile_repository.dart';

/// Use case for deleting user profile picture
class DeleteProfilePictureUseCase extends UseCase<void, NoParams> {
  const DeleteProfilePictureUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<void>> call([NoParams? params]) async {
    return await _repository.deleteProfilePicture();
  }
}
