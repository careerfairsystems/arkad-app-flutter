import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/reset_password_use_case.dart';

class ResetPasswordCommand
    extends ParameterizedCommand<ResetPasswordParams, void> {
  ResetPasswordCommand(this._resetPasswordUseCase);

  final ResetPasswordUseCase _resetPasswordUseCase;

  @override
  Future<void> executeWithParams(ResetPasswordParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _resetPasswordUseCase.call(params);

      result.when(
        success: (_) => setResult(null),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'reset_password',
          ),
        );
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }

  /// Request password reset for email
  Future<void> resetPassword(String email) async {
    await executeWithParams(ResetPasswordParams(email: email));
  }
}
