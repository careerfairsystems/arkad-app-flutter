import 'package:flutter/foundation.dart';

import '../../domain/result.dart';
import '../../errors/app_error.dart';

/// Base repository class providing common functionality for all repositories
/// Handles error mapping, result transformation, and logging
abstract class BaseRepository {
  const BaseRepository();

  /// Execute an operation with consistent error handling and result mapping
  ///
  /// [operation] - The async operation to execute
  /// [errorContext] - Context string for error logging (e.g., "sign in", "load profile")
  /// [onSuccess] - Optional callback for successful operations
  /// [onError] - Optional callback for error handling
  Future<Result<T>> executeOperation<T>(
    Future<T> Function() operation,
    String errorContext, {
    void Function(T result)? onSuccess,
    void Function(AppError error)? onError,
  }) async {
    try {
      final result = await operation();
      onSuccess?.call(result);
      return Result.success(result);
    } catch (e, stackTrace) {
      final appError = _mapException(e, errorContext);

      // Log error for debugging (in development mode)
      _logError(appError, stackTrace);

      onError?.call(appError);
      return Result.failure(appError);
    }
  }

  /// Execute an operation that might return null and handle it appropriately
  Future<Result<T>> executeNullableOperation<T>(
    Future<T?> Function() operation,
    String errorContext,
    String notFoundMessage, {
    void Function(T result)? onSuccess,
    void Function(AppError error)? onError,
  }) async {
    try {
      final result = await operation();
      if (result == null) {
        final error = UnknownError('Data not found: $notFoundMessage');
        onError?.call(error);
        return Result.failure(error);
      }

      onSuccess?.call(result);
      return Result.success(result);
    } catch (e, stackTrace) {
      final appError = _mapException(e, errorContext);

      _logError(appError, stackTrace);

      onError?.call(appError);
      return Result.failure(appError);
    }
  }

  /// Execute multiple operations in parallel and combine their results
  Future<Result<List<T>>> executeParallelOperations<T>(
    List<Future<T> Function()> operations,
    String errorContext,
  ) async {
    try {
      final futures = operations.map((op) => op()).toList();
      final results = await Future.wait(futures);
      return Result.success(results);
    } catch (e, stackTrace) {
      final appError = _mapException(e, errorContext);
      _logError(appError, stackTrace);
      return Result.failure(appError);
    }
  }

  /// Execute an operation with retry logic
  Future<Result<T>> executeWithRetry<T>(
    Future<T> Function() operation,
    String errorContext, {
    int maxRetries = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(Exception)? shouldRetry,
  }) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < maxRetries) {
      try {
        final result = await operation();
        return Result.success(result);
      } catch (e) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(lastException)) {
          break;
        }

        // If this was the last attempt, don't delay
        if (attempts < maxRetries) {
          await Future.delayed(delay);
        }
      }
    }

    final appError = _mapException(
      lastException!,
      '$errorContext (after $attempts attempts)',
    );

    _logError(appError, StackTrace.current);
    return Result.failure(appError);
  }

  /// Check if an error is recoverable/retryable
  bool isRetryableError(Exception error) {
    // Network errors are typically retryable
    if (error.toString().contains('network') ||
        error.toString().contains('connection') ||
        error.toString().contains('timeout')) {
      return true;
    }

    // Server errors (5xx) are typically retryable
    if (error.toString().contains('500') ||
        error.toString().contains('502') ||
        error.toString().contains('503') ||
        error.toString().contains('504')) {
      return true;
    }

    return false;
  }

  /// Map an exception to an AppError
  AppError _mapException(dynamic exception, String context) {
    // For now, create a generic UnknownError
    // This can be enhanced to handle specific exception types
    return UnknownError('$context failed: ${exception.toString()}');
  }

  /// Log error for debugging purposes
  void _logError(AppError error, StackTrace stackTrace) {
    // In development, print detailed error information
    if (kDebugMode) {
      print('Repository Error: ${error.userMessage}');
      print('Technical details: ${error.technicalDetails}');
      print('Stack trace: $stackTrace');
    }

    // In production, you might want to send to crash reporting service
    // crashlytics.recordError(error, stackTrace);
  }
}

/// Repository mixin for caching functionality
mixin CachedRepositoryMixin<T> {
  final Map<String, _CacheEntry<T>> _cache = {};

  /// Cache duration for different types of data
  Duration get cacheExpiration => const Duration(minutes: 5);

  /// Get cached data if available and not expired
  T? getCached(String key) {
    final entry = _cache[key];
    if (entry == null || entry.isExpired) {
      _cache.remove(key);
      return null;
    }
    return entry.data;
  }

  /// Cache data with expiration
  void setCache(String key, T data) {
    _cache[key] = _CacheEntry(data, DateTime.now().add(cacheExpiration));
  }

  /// Clear all cached data
  void clearCache() {
    _cache.clear();
  }

  /// Clear specific cached item
  void clearCacheItem(String key) {
    _cache.remove(key);
  }

  /// Execute operation with caching
  Future<Result<R>> executeWithCache<R>(
    String cacheKey,
    Future<Result<R>> Function() operation, {
    bool forceRefresh = false,
  }) async {
    // Check cache first (unless force refresh is requested)
    if (!forceRefresh) {
      final cached = getCached(cacheKey);
      if (cached is R) {
        return Result.success(cached);
      }
    }

    // Execute operation
    final result = await operation();

    // Cache successful results
    result.when(
      success: (data) => setCache(cacheKey, data as T),
      failure: (_) {}, // Don't cache failures
    );

    return result;
  }
}

/// Internal cache entry class
class _CacheEntry<T> {
  final T data;
  final DateTime expiration;

  _CacheEntry(this.data, this.expiration);

  bool get isExpired => DateTime.now().isAfter(expiration);
}
