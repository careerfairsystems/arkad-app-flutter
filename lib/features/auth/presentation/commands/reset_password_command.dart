import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/reset_password_use_case.dart';

class ResetPasswordCommand extends ParameterizedCommand<ResetPasswordParams, void> {
  ResetPasswordCommand(this._resetPasswordUseCase);

  final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  Future<void> executeWithParams(ResetPasswordParams params) async {
    if (isExecuting) return;

    setExecuting(true);

    final result = await _resetPasswordUseCase.call(params);

    result.when(
      success: (_) => setResult(null),
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  Future<void> resetPassword(String email) async {
    await executeWithParams(ResetPasswordParams(email: email));
  }
}