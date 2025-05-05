/// Represents an item in the navigation history for bottom navigation.
class NavigationHistoryItem {
  /// The index of the tab in the bottom navigation.
  final int tabIndex;

  /// The route name for this navigation item.
  final String route;

  /// Optional in-tab route for detailed navigation tracking.
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

/// Maintains a stack of navigation history for the bottom navigation.
///
/// This class is used to track tab switching and in-tab navigation for a smooth UX.
class NavigationHistory {
  final List<NavigationHistoryItem> _history = [];

  /// Adds a new navigation item to the history.
  /// Avoids adding consecutive duplicates.
  void push(int tabIndex, String route, {String? inTabRoute}) {
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

  /// Removes the most recent history item and returns the previous one.
  /// Returns null if there's only one or zero items in the history.
  NavigationHistoryItem? pop() {
    if (_history.length <= 1) {
      return null;
    }
    _history.removeLast();
    return _history.isNotEmpty ? _history.last : null;
  }

  /// The current (most recent) navigation item.
  NavigationHistoryItem? get current =>
      _history.isNotEmpty ? _history.last : null;

  /// Clears all navigation history.
  void clear() {
    _history.clear();
  }

  /// Whether the history has more than one entry.
  bool get hasMultipleEntries => _history.length > 1;
}
