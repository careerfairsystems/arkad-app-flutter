/// Result pattern for handling success and failure cases consistently
sealed class Result<T> {
  const Result();

  /// Create a success result
  factory Result.success(T value) = Success<T>;

  /// Create a failure result
  factory Result.failure(AppError error) = Failure<T>;

  /// Pattern match on the result
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  });

  /// Map the success value to a new type
  Result<U> map<U>(U Function(T value) transform) {
    return when(
      success: (value) => Result.success(transform(value)),
      failure: (error) => Result.failure(error),
    );
  }

  /// Check if this is a success result
  bool get isSuccess => this is Success<T>;

  /// Check if this is a failure result
  bool get isFailure => this is Failure<T>;

  /// Get the success value or null
  T? get valueOrNull => when(
    success: (value) => value,
    failure: (_) => null,
  );

  /// Get the error or null
  AppError? get errorOrNull => when(
    success: (_) => null,
    failure: (error) => error,
  );
}

/// Success result containing a value
class Success<T> extends Result<T> {
  const Success(this.value);

  final T value;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      success(value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Failure result containing an error
class Failure<T> extends Result<T> {
  const Failure(this.error);

  final AppError error;

  @override
  R when<R>({
    required R Function(T value) success,
    required R Function(AppError error) failure,
  }) =>
      failure(error);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure<T> && runtimeType == other.runtimeType && error == other.error;

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure($error)';
}

// Import the AppError class
import '../../shared/errors/app_error.dart';