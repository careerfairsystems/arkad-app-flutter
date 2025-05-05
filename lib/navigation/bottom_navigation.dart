import 'package:flutter/material.dart';

/// Represents an item in the bottom navigation bar.
class NavigationItem {
  /// The label shown below the icon.
  final String label;

  /// The icon to display for this item.
  final IconData icon;

  /// The route associated with this item.
  final String route;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

/// A customized bottom navigation bar for the app.
///
/// This widget displays the navigation items and handles tab switching.
class AppBottomNavigation extends StatelessWidget {
  /// The index of the currently selected tab.
  final int currentIndex;

  /// Callback when a tab is tapped.
  final Function(int) onTap;

  /// The list of navigation items to display.
  final List<NavigationItem> items;

  const AppBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex < items.length ? currentIndex : 0,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: items.map((item) => _buildNavigationBarItem(item)).toList(),
    );
  }

  /// Creates a BottomNavigationBarItem from a NavigationItem.
  BottomNavigationBarItem _buildNavigationBarItem(NavigationItem item) {
    return BottomNavigationBarItem(
      icon: Icon(item.icon),
      label: item.label,
    );
  }
}
