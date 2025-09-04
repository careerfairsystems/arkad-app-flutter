import '../../../../shared/errors/app_error.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/resend_verification_use_case.dart';

class ResendVerificationCommand extends ParameterizedCommand<ResendVerificationParams, void> {
  ResendVerificationCommand(this._resendVerificationUseCase);

  final ResendVerificationUseCase _resendVerificationUseCase;

  @override
  Future<void> executeWithParams(ResendVerificationParams params) async {
    if (isExecuting) return;

    setExecuting(true);

    try {
      final result = await _resendVerificationUseCase.call(params);

      result.when(
        success: (_) => setResult(null),
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(UnknownError(e.toString()));
    } finally {
      setExecuting(false);
    }
  }

  Future<void> resendVerification(String email) async {
    await executeWithParams(ResendVerificationParams(email: email));
  }
}