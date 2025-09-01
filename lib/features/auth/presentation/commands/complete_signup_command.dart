import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';

/// Command for complete signup operation
class CompleteSignupCommand extends ParameterizedCommand<CompleteSignupParams, AuthSession> {
  CompleteSignupCommand(this._completeSignupUseCase);

  final CompleteSignupUseCase _completeSignupUseCase;

  @override
  Future<void> executeWithParams(CompleteSignupParams params) async {
    if (isExecuting) return; // Prevent multiple concurrent executions

    setExecuting(true);

    final result = await _completeSignupUseCase.call(params);

    result.when(
      success: (session) => setResult(session),
      failure: (error) => setError(error),
    );

    setExecuting(false);
  }

  /// Convenience method for executing with individual parameters
  Future<void> completeSignup({
    required String signupToken,
    required String verificationCode,
    required SignupData signupData,
  }) async {
    await executeWithParams(CompleteSignupParams(
      signupToken: signupToken,
      verificationCode: verificationCode,
      signupData: signupData,
    ));
  }
}