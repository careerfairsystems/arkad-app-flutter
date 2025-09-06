import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for getting current user profile
class GetCurrentProfileUseCase extends NoParamsUseCase<Profile> {
  const GetCurrentProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> call() async {
    return await _repository.getCurrentProfile();
  }
}
