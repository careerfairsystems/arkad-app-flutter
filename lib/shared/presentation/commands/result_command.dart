import '../../domain/result.dart';
import '../../errors/app_error.dart';
import 'base_command.dart';

/// Command that returns a boolean success indicator while maintaining result data
abstract class ResultCommand<T> extends Command<T> {
  /// Execute the command and return success status
  Future<bool> executeForResult();

  @override
  Future<void> execute() async {
    await executeForResult();
  }
}

/// Parameterized command that returns a boolean success indicator
abstract class ParameterizedResultCommand<TParams, TResult> extends ParameterizedCommand<TParams, TResult> {
  /// Execute the command with parameters and return success status
  Future<bool> executeForResultWithParams(TParams params);

  @override
  Future<void> executeWithParams(TParams params) async {
    await executeForResultWithParams(params);
  }
}

/// Generic implementation of a result command that wraps a use case
class GenericResultCommand<TParams, TResult> extends ParameterizedResultCommand<TParams, TResult> {
  GenericResultCommand(this._operation);

  final Future<Result<TResult>> Function(TParams params) _operation;

  @override
  Future<bool> executeForResultWithParams(TParams params) async {
    if (isExecuting) return false;

    setExecuting(true);

    try {
      final result = await _operation(params);
      
      return result.when(
        success: (value) {
          setResult(value);
          return true;
        },
        failure: (error) {
          setError(error);
          return false;
        },
      );
    } catch (e) {
      setError(UnknownError('Operation failed: $e'));
      return false;
    } finally {
      setExecuting(false);
    }
  }
}