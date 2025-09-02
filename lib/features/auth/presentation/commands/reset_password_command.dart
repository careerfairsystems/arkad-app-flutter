import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/reset_password_use_case.dart';

/// Command for reset password operation
class ResetPasswordCommand extends ParameterizedCommand<ResetPasswordParams, void> {
  ResetPasswordCommand(this._resetPasswordUseCase);

  final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  Future<void> executeWithParams(ResetPasswordParams params) async {
    if (isExecuting) return; // Prevent multiple concurrent executions

    setExecuting(true);

    final result = await _resetPasswordUseCase.call(params);

    result.when(
      success: (_) => setResult(null), // Reset password returns void
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  /// Convenience method for executing with email
  Future<void> resetPassword(String email) async {
    await executeWithParams(ResetPasswordParams(email: email));
  }
}