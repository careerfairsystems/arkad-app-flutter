import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/use_cases/sign_in_use_case.dart';

/// Command for sign in operation
class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  SignInCommand(this._signInUseCase);

  final SignInUseCase _signInUseCase;

  @override
  Future<void> executeWithParams(SignInParams params) async {
    if (isExecuting) return; // Prevent multiple concurrent executions

    setExecuting(true);

    final result = await _signInUseCase.call(params);

    result.when(
      success: (session) => setResult(session),
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  /// Convenience method for executing with email and password
  Future<void> signIn(String email, String password) async {
    await executeWithParams(SignInParams(email: email, password: password));
  }
}