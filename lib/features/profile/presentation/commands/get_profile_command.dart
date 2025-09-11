import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/get_current_profile_use_case.dart';

/// Command for loading current user profile
class GetProfileCommand extends Command<Profile> {
  final GetCurrentProfileUseCase _useCase;

  GetProfileCommand(this._useCase);

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    clearError(); 
    setExecuting(true);

    try {
      final result = await _useCase();
      result.when(
        success: (profile) => setResult(profile),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'get_profile',
          ),
        );
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }
}
