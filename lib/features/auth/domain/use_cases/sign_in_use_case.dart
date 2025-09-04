import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

/// Use case for signing in a user
class SignInUseCase extends UseCase<AuthSession, SignInParams> {
  const SignInUseCase(this._repository);

  final AuthRepository _repository;

  @override
  Future<Result<AuthSession>> call(SignInParams params) async {
    // Validate input
    if (params.email.isEmpty || params.password.isEmpty) {
      return Result.failure(
        const ValidationError("Email and password are required"),
      );
    }

    if (!ValidationService.isValidEmail(params.email)) {
      return Result.failure(
        const ValidationError("Please enter a valid email address"),
      );
    }

    if (params.password.length < 8) {
      return Result.failure(
        const ValidationError("Password must be at least 8 characters"),
      );
    }

    // Attempt sign in
    return await _repository.signIn(params.email.trim(), params.password);
  }
}

/// Parameters for sign in use case
class SignInParams {
  const SignInParams({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignInParams &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password;

  @override
  int get hashCode => Object.hash(email, password);
}