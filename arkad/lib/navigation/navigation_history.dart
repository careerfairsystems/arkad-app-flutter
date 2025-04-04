import 'package:flutter/material.dart';

class NavigationHistoryItem {
  final int tabIndex;
  final String route;
  // Add a more detailed path for in-tab navigation
  final String? inTabRoute;

  NavigationHistoryItem({
    required this.tabIndex,
    required this.route,
    this.inTabRoute,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationHistoryItem &&
        other.tabIndex == tabIndex &&
        other.route == route &&
        other.inTabRoute == inTabRoute;
  }

  @override
  int get hashCode =>
      tabIndex.hashCode ^ route.hashCode ^ (inTabRoute?.hashCode ?? 0);
}

class NavigationHistory {
  final List<NavigationHistoryItem> _history = [];

  void push(int tabIndex, String route, {String? inTabRoute}) {
    // Avoid adding duplicates consecutively
    if (_history.isNotEmpty) {
      final last = _history.last;
      if (last.tabIndex == tabIndex &&
          last.route == route &&
          last.inTabRoute == inTabRoute) {
        return;
      }
    }
    _history.add(NavigationHistoryItem(
      tabIndex: tabIndex,
      route: route,
      inTabRoute: inTabRoute,
    ));
  }

  NavigationHistoryItem? pop() {
    if (_history.length <= 1) {
      return null;
    }
    _history.removeLast();
    return _history.isNotEmpty ? _history.last : null;
  }

  NavigationHistoryItem? get current =>
      _history.isNotEmpty ? _history.last : null;

  NavigationHistoryItem? get previous =>
      _history.length > 1 ? _history[_history.length - 2] : null;

  void clear() {
    _history.clear();
  }

  int get length => _history.length;

  bool get isEmpty => _history.isEmpty;

  bool get hasMultipleEntries => _history.length > 1;

  // Debug helper method
  void printHistory() {
    print('Navigation History (${_history.length} items):');
    for (var i = 0; i < _history.length; i++) {
      final item = _history[i];
      print(
          '[$i] Tab: ${item.tabIndex}, Route: ${item.route}, InTabRoute: ${item.inTabRoute}');
    }
  }
}
