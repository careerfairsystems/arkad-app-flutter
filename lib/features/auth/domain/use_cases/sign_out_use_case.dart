import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing out current user
class SignOutUseCase extends NoParamsUseCase<void> {
  const SignOutUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call() async {
    return await _repository.signOut();
  }
}
