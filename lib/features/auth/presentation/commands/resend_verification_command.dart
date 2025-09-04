import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/resend_verification_use_case.dart';

/// Command for resend verification code operation
class ResendVerificationCommand extends ParameterizedCommand<ResendVerificationParams, void> {
  ResendVerificationCommand(this._resendVerificationUseCase);

  final ResendVerificationUseCase _resendVerificationUseCase;

  @override
  Future<void> executeWithParams(ResendVerificationParams params) async {
    if (isExecuting) return; // Prevent multiple concurrent executions

    setExecuting(true);

    final result = await _resendVerificationUseCase.call(params);

    result.when(
      success: (_) => setResult(null), // Resend verification returns void
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  /// Convenience method for executing with email
  Future<void> resendVerification(String email) async {
    await executeWithParams(ResendVerificationParams(email: email));
  }
}