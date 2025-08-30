import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/sign_up_use_case.dart';

/// Command for sign up operation
class SignUpCommand extends ParameterizedCommand<SignupData, String> {
  SignUpCommand(this._signUpUseCase);

  final SignUpUseCase _signUpUseCase;

  @override
  Future<void> executeWithParams(SignupData params) async {
    if (isExecuting) return; // Prevent multiple concurrent executions

    setExecuting(true);

    final result = await _signUpUseCase.call(params);

    result.when(
      success: (token) => setResult(token),
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  /// Convenience method for executing with signup data
  Future<void> signUp(SignupData signupData) async {
    await executeWithParams(signupData);
  }
}