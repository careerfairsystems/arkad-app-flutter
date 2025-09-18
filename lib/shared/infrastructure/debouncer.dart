import 'dart:async';

/// A utility class that delays function execution until after a specified duration
/// has elapsed since the last invocation. Useful for search functionality.
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  void call(void Function() callback) {
    _timer?.cancel();
    _timer = Timer(delay, callback);
  }

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    cancel();
  }

  bool get isPending => _timer?.isActive ?? false;
}

/// Specialized debouncer for search functionality (300ms delay)
class SearchDebouncer extends Debouncer {
  SearchDebouncer() : super(delay: const Duration(milliseconds: 300));
  SearchDebouncer.withDelay(Duration delay) : super(delay: delay);
}

/// Specialized debouncer for filter functionality (200ms delay)
class FilterDebouncer extends Debouncer {
  FilterDebouncer() : super(delay: const Duration(milliseconds: 200));
  FilterDebouncer.withDelay(Duration delay) : super(delay: delay);
}
