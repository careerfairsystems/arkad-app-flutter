import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/signup_data.dart';
import '../repositories/auth_repository.dart';

/// Use case for resending verification code
class ResendVerificationUseCase
    extends UseCase<String, ResendVerificationParams> {
  const ResendVerificationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<String>> call(ResendVerificationParams params) async {
    // Validate signup data
    if (!params.signupData.isValid) {
      return Result.failure(const ValidationError("Invalid signup data"));
    }

    // Request new verification code and get new token
    return await _repository.requestVerificationCode(params.signupData);
  }
}

/// Parameters for resend verification use case
class ResendVerificationParams {
  const ResendVerificationParams({required this.signupData});

  final SignupData signupData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResendVerificationParams &&
          runtimeType == other.runtimeType &&
          signupData == other.signupData;

  @override
  int get hashCode => signupData.hashCode;
}
