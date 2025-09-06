import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/resend_verification_use_case.dart';

class ResendVerificationCommand extends ParameterizedCommand<ResendVerificationParams, void> {
  ResendVerificationCommand(this._resendVerificationUseCase);

  final ResendVerificationUseCase _resendVerificationUseCase;

  @override
  Future<void> executeWithParams(ResendVerificationParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _resendVerificationUseCase.call(params);

      result.when(
        success: (_) => setResult(null),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(ErrorMapper.fromDioException(e, null, operationContext: 'resend_verification'));
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }

  /// Resend verification code to email
  Future<void> resendVerification(String email) async {
    await executeWithParams(ResendVerificationParams(email: email));
  }
}