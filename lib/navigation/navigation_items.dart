import 'package:flutter/material.dart';

/// Adds `branchIndex` so the BottomNavigationBar knows which **Navigator branch**
/// a tab belongs to.  The branch order never changes; we just
/// build different *subsets* of the list depending on auth‑state.
class NavigationItem {
  final String label;
  final String route;
  final IconData icon;
  final int branchIndex;
  const NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.branchIndex,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// Branch order (fixed):
// 0  Companies   /companies           (public)
// 1  Map         /map                 (public)
// 2  Sessions    /sessions            (public)
// 3  Events      /events              (public)
// 4  Profile     /profile             (auth required)
// 5  Login       /auth/login          (when not authenticated)
// ──────────────────────────────────────────────────────────────────────────────

class NavigationItems {
  static const _companies = NavigationItem(
    label: 'Companies',
    route: '/companies',
    icon: Icons.business,
    branchIndex: 0,
  );
  static const _map = NavigationItem(
    label: 'Map',
    route: '/map',
    icon: Icons.map,
    branchIndex: 1,
  );
  static const _sessions = NavigationItem(
    label: 'Sessions',
    route: '/sessions',
    icon: Icons.people,
    branchIndex: 2,
  );
  static const _events = NavigationItem(
    label: 'Events',
    route: '/events',
    icon: Icons.event,
    branchIndex: 3,
  );
  static const _profile = NavigationItem(
    label: 'Profile',
    route: '/profile',
    icon: Icons.person,
    branchIndex: 4,
  );
  static const _login = NavigationItem(
    label: 'Login',
    route: '/auth/login',
    icon: Icons.login,
    branchIndex: 5,
  );

  static List<NavigationItem> forAuth(bool authenticated) =>
      authenticated
          ? const [_companies, _map, _sessions, _events, _profile]
          : const [_companies, _map, _sessions, _events, _login];
}
