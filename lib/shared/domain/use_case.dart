import 'result.dart';

/// Base class for all use cases
abstract class UseCase<Type, Params> {
  const UseCase();

  Future<Result<Type>> call(Params params);
}

/// Base class for use cases that don't require parameters
abstract class NoParamsUseCase<Type> {
  const NoParamsUseCase();

  Future<Result<Type>> call();
}

/// Base class for synchronous use cases
abstract class SyncUseCase<Type, Params> {
  const SyncUseCase();

  Result<Type> call(Params params);
}

/// No parameters marker for use cases
class NoParams {
  const NoParams();
}
