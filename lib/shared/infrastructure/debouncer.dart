import 'dart:async';

import 'package:flutter/foundation.dart';

/// A utility class that delays function execution until after wait milliseconds
/// have elapsed since the last time the debounced function was invoked.
///
/// This is particularly useful for search functionality where you want to wait
/// for the user to stop typing before executing expensive operations.
class Debouncer {
  /// The duration to wait before executing the debounced function
  final Duration delay;

  /// Internal timer used for debouncing
  Timer? _timer;

  /// Creates a debouncer with the specified delay
  Debouncer({required this.delay});

  /// Debounces the execution of the provided callback
  ///
  /// If this method is called again before the delay has elapsed,
  /// the previous timer is cancelled and a new one is started.
  void call(VoidCallback callback) {
    // Cancel any existing timer
    _timer?.cancel();

    // Start a new timer
    _timer = Timer(delay, callback);
  }

  /// Cancels any pending debounced function execution
  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes of the debouncer and cancels any pending execution
  ///
  /// This should be called when the debouncer is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    cancel();
  }

  /// Returns true if there's a pending debounced function execution
  bool get isPending => _timer?.isActive ?? false;
}

/// A specialized debouncer for search functionality with common defaults
class SearchDebouncer extends Debouncer {
  /// Creates a search debouncer with a 300ms delay (optimal for search UX)
  SearchDebouncer() : super(delay: const Duration(milliseconds: 300));

  /// Creates a search debouncer with a custom delay
  SearchDebouncer.withDelay(Duration delay) : super(delay: delay);
}

/// A specialized debouncer for filter functionality with shorter delays
class FilterDebouncer extends Debouncer {
  /// Creates a filter debouncer with a 200ms delay (faster for filter UX)
  FilterDebouncer() : super(delay: const Duration(milliseconds: 200));

  /// Creates a filter debouncer with a custom delay
  FilterDebouncer.withDelay(Duration delay) : super(delay: delay);
}
