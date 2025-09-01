import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../repositories/auth_repository.dart';

/// Use case for requesting password reset
class ResetPasswordUseCase extends UseCase<void, ResetPasswordParams> {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<void>> call(ResetPasswordParams params) async {
    // Validate email
    if (params.email.isEmpty) {
      return Result.failure(
        const ValidationError("Email is required"),
      );
    }

    if (!_isValidEmail(params.email)) {
      return Result.failure(
        const ValidationError("Please enter a valid email address"),
      );
    }

    // Attempt password reset
    return await _repository.resetPassword(params.email.trim());
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Parameters for reset password use case
class ResetPasswordParams {
  const ResetPasswordParams({
    required this.email,
  });

  final String email;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResetPasswordParams &&
          runtimeType == other.runtimeType &&
          email == other.email;

  @override
  int get hashCode => email.hashCode;
}