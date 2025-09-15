import 'package:dio/dio.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/delete_cv_use_case.dart';

/// Command for deleting user CV document
class DeleteCVCommand extends VoidCommand {
  final DeleteCVUseCase _useCase;

  DeleteCVCommand(this._useCase);

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
          ErrorMapper.fromDioException(e, null, operationContext: 'delete_cv'),
        );
      } else {
        setError(
          ErrorMapper.fromException(e, null, operationContext: 'delete_cv'),
        );
      }
    } finally {
      setExecuting(false);
    }
  }
}
