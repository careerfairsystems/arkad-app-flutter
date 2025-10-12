import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/signup_data.dart';
import '../repositories/auth_repository.dart';

/// Use case for beginning user signup
class SignUpUseCase extends UseCase<String, SignupData> {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<String>> call(SignupData params) async {
    // Validate signup data
    if (!params.isValid) {
      return Result.failure(
        const ValidationError("Please check your signup information"),
      );
    }

    // Validate password requirements using domain validation service
    if (!ValidationService.isStrongPassword(params.password)) {
      return Result.failure(
        const ValidationError(
          "Password must be at least 8 characters with uppercase, lowercase and numbers",
        ),
      );
    }

    // Validate optional fields if provided
    if (params.firstName?.isEmpty == true) {
      return Result.failure(
        const ValidationError("First name cannot be empty"),
      );
    }

    if (params.lastName?.isEmpty == true) {
      return Result.failure(const ValidationError("Last name cannot be empty"));
    }

    // Attempt signup
    return await _repository.beginSignup(params);
  }
}
