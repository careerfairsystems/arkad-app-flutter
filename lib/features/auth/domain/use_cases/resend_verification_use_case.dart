import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/errors/app_error.dart';
import '../repositories/auth_repository.dart';

/// Use case for resending verification code
class ResendVerificationUseCase extends UseCase<void, ResendVerificationParams> {
  const ResendVerificationUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(ResendVerificationParams params) async {
    // Validate email
    if (params.email.isEmpty) {
      return Result.failure(
        const ValidationError("Email is required"),
      );
    }

    if (!ValidationService.isValidEmail(params.email)) {
      return Result.failure(
        const ValidationError("Please enter a valid email address"),
      );
    }

    // Request new verification code
    return await _repository.requestVerificationCode(params.email.trim());
  }

  // Email validation now handled by ValidationService
}

/// Parameters for resend verification use case
class ResendVerificationParams {
  const ResendVerificationParams({
    required this.email,
  });

  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResendVerificationParams &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}