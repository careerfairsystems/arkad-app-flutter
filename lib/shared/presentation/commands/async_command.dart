import '../../domain/result.dart';
import '../../errors/app_error.dart';
import 'base_command.dart';

/// Command that wraps async operations with automatic state management
class AsyncCommand<T> extends Command<T> {
  AsyncCommand(this._operation);

  final Future<Result<T>> Function() _operation;

  @override
  Future<void> execute() async {
    if (isExecuting) return; // Prevent concurrent executions

    setExecuting(true);

    try {
      final result = await _operation();

      result.when(
        success: (value) => setResult(value),
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(UnknownError('Unexpected error: $e'));
    } finally {
      setExecuting(false);
    }
  }
}

/// Parameterized async command
class AsyncParameterizedCommand<TParams, TResult>
    extends ParameterizedCommand<TParams, TResult> {
  AsyncParameterizedCommand(this._operation);

  final Future<Result<TResult>> Function(TParams params) _operation;

  @override
  Future<void> executeWithParams(TParams params) async {
    if (isExecuting) return; // Prevent concurrent executions

    setExecuting(true);

    try {
      final result = await _operation(params);

      result.when(
        success: (value) => setResult(value),
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(UnknownError('Unexpected error: $e'));
    } finally {
      setExecuting(false);
    }
  }
}

/// Simple command for operations that can't fail
class SimpleAsyncCommand<T> extends Command<T> {
  SimpleAsyncCommand(this._operation);

  final Future<T> Function() _operation;

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    setExecuting(true);

    try {
      final result = await _operation();
      setResult(result);
    } catch (e) {
      setError(UnknownError('Operation failed: $e'));
    } finally {
      setExecuting(false);
    }
  }
}
