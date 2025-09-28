import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case for refreshing the current authentication session
/// This fetches fresh user profile data from the backend
class RefreshSessionUseCase extends NoParamsUseCase<AuthSession> {
  const RefreshSessionUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call() async {
    return await _repository.refreshSession();
  }
}
