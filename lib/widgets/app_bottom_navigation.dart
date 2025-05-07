import 'package:flutter/material.dart';
import '../navigation/navigation_items.dart';

class AppBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final List<NavigationItem> items;

  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: [
        for (final item in items)
          BottomNavigationBarItem(icon: Icon(item.icon), label: item.label)
      ],
    );
  }
}
