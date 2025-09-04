import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/use_cases/sign_in_use_case.dart';

class SignInCommand extends ParameterizedCommand<SignInParams, AuthSession> {
  SignInCommand(this._signInUseCase);

  final SignInUseCase _signInUseCase;

  @override
  Future<void> executeWithParams(SignInParams params) async {
    if (isExecuting) return;

    setExecuting(true);

    try {
      final result = await _signInUseCase.call(params);

      result.when(
        success: (session) => setResult(session),
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(UnknownError(e.toString()));
    } finally {
      setExecuting(false);
    }
  }

  Future<void> signIn(String email, String password) async {
    await executeWithParams(SignInParams(email: email, password: password));
  }
}