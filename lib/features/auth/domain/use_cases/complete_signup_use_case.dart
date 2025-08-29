import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/auth_session.dart';
import '../entities/signup_data.dart';
import '../repositories/auth_repository.dart';

/// Use case for completing user signup with verification code
class CompleteSignupUseCase extends UseCase<AuthSession, CompleteSignupParams> {
  const CompleteSignupUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(CompleteSignupParams params) async {
    // Validate verification code
    if (params.verificationCode.isEmpty) {
      return Result.failure(
        const ValidationError("Verification code is required"),
      );
    }

    if (params.verificationCode.length != 6) {
      return Result.failure(
        const ValidationError("Verification code must be 6 digits"),
      );
    }

    // Ensure verification code is numeric
    if (!RegExp(r'^\d{6}$').hasMatch(params.verificationCode)) {
      return Result.failure(
        const ValidationError("Verification code must contain only numbers"),
      );
    }

    // Validate token
    if (params.signupToken.isEmpty) {
      return Result.failure(
        const ValidationError("Invalid signup session. Please try again."),
      );
    }

    // Validate signup data
    if (!params.signupData.isValid) {
      return Result.failure(
        const ValidationError("Invalid signup data. Please try again."),
      );
    }

    // Attempt to complete signup
    return await _repository.completeSignup(
      params.signupToken,
      params.verificationCode,
      params.signupData,
    );
  }
}

/// Parameters for complete signup use case
class CompleteSignupParams {
  const CompleteSignupParams({
    required this.signupToken,
    required this.verificationCode,
    required this.signupData,
  });

  final String signupToken;
  final String verificationCode;
  final SignupData signupData;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CompleteSignupParams &&
          runtimeType == other.runtimeType &&
          signupToken == other.signupToken &&
          verificationCode == other.verificationCode &&
          signupData == other.signupData;

  @override
  int get hashCode => Object.hash(signupToken, verificationCode, signupData);
}