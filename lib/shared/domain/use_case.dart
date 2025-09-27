import 'result.dart';

/// Base class for all use cases
abstract class UseCase<TResult, Params> {
  const UseCase();

  Future<Result<TResult>> call(Params params);
}

/// Base class for use cases that don't require parameters
abstract class NoParamsUseCase<TResult> {
  const NoParamsUseCase();

  Future<Result<TResult>> call();
}

/// Base class for synchronous use cases
abstract class SyncUseCase<TResult, Params> {
  const SyncUseCase();

  Result<TResult> call(Params params);
}

/// No parameters marker for use cases
class NoParams {
  const NoParams();
}
