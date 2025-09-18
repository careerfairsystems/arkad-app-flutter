import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/complete_signup_use_case.dart';

class CompleteSignupCommand
    extends ParameterizedCommand<CompleteSignupParams, AuthSession> {
  CompleteSignupCommand(this._completeSignupUseCase);

  final CompleteSignupUseCase _completeSignupUseCase;

  @override
  Future<void> executeWithParams(CompleteSignupParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _completeSignupUseCase.call(params);

      result.when(
        success: (session) => setResult(session),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'complete_signup',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(
            e,
            null,
            operationContext: 'complete_signup',
          ),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  /// Complete signup process with verification code
  Future<void> completeSignup({
    required String signupToken,
    required String verificationCode,
    required SignupData signupData,
  }) async {
    await executeWithParams(
      CompleteSignupParams(
        signupToken: signupToken,
        verificationCode: verificationCode,
        signupData: signupData,
      ),
    );
  }
}
