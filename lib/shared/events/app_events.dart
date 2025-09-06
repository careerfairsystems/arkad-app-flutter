import 'dart:async';

/// Simple event bus for cross-feature communication
class AppEvents {
  static final _AppEventBus _instance = _AppEventBus();

  /// Subscribe to events of type T
  static Stream<T> on<T>() => _instance._getStream<T>();

  /// Fire an event
  static void fire(Object event) => _instance._fire(event);

  /// Clear all subscriptions (useful for testing)
  static void clear() => _instance._clear();
}

class _AppEventBus {
  final Map<Type, StreamController> _controllers = {};

  Stream<T> _getStream<T>() {
    final controller =
        _controllers.putIfAbsent(T, () => StreamController<T>.broadcast())
            as StreamController<T>;

    return controller.stream;
  }

  void _fire(Object event) {
    final controller = _controllers[event.runtimeType];
    if (controller != null && !controller.isClosed) {
      controller.add(event);
    }
  }

  void _clear() {
    for (final controller in _controllers.values) {
      if (!controller.isClosed) {
        controller.close();
      }
    }
    _controllers.clear();
  }
}
