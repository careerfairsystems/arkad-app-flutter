import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
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

    // Validate password requirements
    final passwordValidation = _validatePassword(params.password);
    if (passwordValidation != null) {
      return Result.failure(ValidationError(passwordValidation));
    }

    // Validate optional fields if provided
    if (params.firstName?.isEmpty == true) {
      return Result.failure(
        const ValidationError("First name cannot be empty"),
      );
    }

    if (params.lastName?.isEmpty == true) {
      return Result.failure(
        const ValidationError("Last name cannot be empty"),
      );
    }

    // Attempt signup
    return await _repository.beginSignup(params);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters";
    }

    if (password.length > 128) {
      return "Password must be less than 128 characters";
    }

    if (!_hasStrongPassword(password)) {
      return "Password must contain at least one letter and one number";
    }

    return null; // Valid password
  }

  bool _hasStrongPassword(String password) {
    final hasLetter = RegExp(r'[a-zA-Z]').hasMatch(password);
    final hasNumber = RegExp(r'[0-9]').hasMatch(password);
    return hasLetter && hasNumber;
  }
}