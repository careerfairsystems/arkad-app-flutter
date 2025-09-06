import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/use_cases/sign_up_use_case.dart';

class SignUpCommand extends ParameterizedCommand<SignupData, String> {
  SignUpCommand(this._signUpUseCase);

  final SignUpUseCase _signUpUseCase;

  @override
  Future<void> executeWithParams(SignupData params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _signUpUseCase.call(params);

      result.when(
        success: (token) => setResult(token),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(ErrorMapper.fromDioException(e, null, operationContext: 'signup'));
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }

  /// Start signup process with user data
  Future<void> signUp(SignupData signupData) async {
    await executeWithParams(signupData);
  }
}