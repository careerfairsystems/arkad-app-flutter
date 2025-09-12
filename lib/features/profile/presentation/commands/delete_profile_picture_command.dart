import 'package:dio/dio.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/delete_profile_picture_use_case.dart';

/// Command for deleting user profile picture
class DeleteProfilePictureCommand extends VoidCommand {
  final DeleteProfilePictureUseCase _useCase;

  DeleteProfilePictureCommand(this._useCase);

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _useCase.call();
      result.when(
        success: (_) => setResult(null),
        failure: (error) => setError(error),
      );
    } catch (e) {
      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(e, null, operationContext: 'delete_profile_picture'),
        );
      } else {
        setError(UnknownError(e.toString()));
      }
    } finally {
      setExecuting(false);
    }
  }
}