import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'bottom_navigation.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/auth/login_screen.dart';

class MainNavigation extends StatefulWidget {
  final String? initialRoute;

  const MainNavigation({Key? key, this.initialRoute}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Create navigator keys for each tab to maintain their state
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Keys for unauthenticated state
  final List<GlobalKey<NavigatorState>> _unauthNavigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Define navigation items for authentication states
  static const List<NavigationItem> _unauthenticatedItems = [
    NavigationItem(
      label: 'Companies',
      icon: Icons.business,
      route: '/companies',
    ),
    NavigationItem(
      label: 'Map',
      icon: Icons.map,
      route: '/map',
    ),
    NavigationItem(
      label: 'Login',
      icon: Icons.login,
      route: '/login',
    ),
  ];

  static const List<NavigationItem> _authenticatedItems = [
    NavigationItem(
      label: 'Companies',
      icon: Icons.business,
      route: '/companies',
    ),
    NavigationItem(
      label: 'Sessions',
      icon: Icons.people,
      route: '/sessions',
    ),
    NavigationItem(
      label: 'Events',
      icon: Icons.event,
      route: '/events',
    ),
    NavigationItem(
      label: 'Map',
      icon: Icons.map,
      route: '/map',
    ),
    NavigationItem(
      label: 'Profile',
      icon: Icons.person,
      route: '/profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setInitialIndex();
  }

  @override
  void didUpdateWidget(MainNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialRoute != oldWidget.initialRoute) {
      _setInitialIndex();
    }
  }

  void _setInitialIndex() {
    if (widget.initialRoute != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final items =
          isAuthenticated ? _authenticatedItems : _unauthenticatedItems;

      for (int i = 0; i < items.length; i++) {
        if (items[i].route == widget.initialRoute) {
          setState(() {
            _currentIndex = i;
          });
          return;
        }
      }
      // Default to first tab if route not found
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final items = isAuthenticated ? _authenticatedItems : _unauthenticatedItems;
    final navigatorKeys =
        isAuthenticated ? _navigatorKeys : _unauthNavigatorKeys;

    // Reset index if it's out of range (e.g. after logging out)
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
    }

    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab =
            !await navigatorKeys[_currentIndex].currentState!.maybePop();

        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: isAuthenticated
              ? _buildAuthenticatedTabNavigators(navigatorKeys)
              : _buildUnauthenticatedTabNavigators(navigatorKeys),
        ),
        bottomNavigationBar: authProvider.status != AuthStatus.initial
            ? AppBottomNavigation(
                currentIndex: _currentIndex,
                onTap: _onTabTapped,
                items: items,
              )
            : null,
      ),
    );
  }

  List<Widget> _buildAuthenticatedTabNavigators(
      List<GlobalKey<NavigatorState>> keys) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return [
      _buildTabNavigator(keys[0], const CompaniesScreen()),
      _buildTabNavigator(keys[1], const StudentSessionsScreen()),
      _buildTabNavigator(keys[2], const EventScreen()),
      _buildTabNavigator(keys[3], const MapScreen()),
      _buildTabNavigator(keys[4], ProfileScreen(user: authProvider.user!)),
    ];
  }

  List<Widget> _buildUnauthenticatedTabNavigators(
      List<GlobalKey<NavigatorState>> keys) {
    return [
      _buildTabNavigator(keys[0], const CompaniesScreen()),
      _buildTabNavigator(keys[1], const MapScreen()),
      _buildTabNavigator(keys[2], const LoginScreen()),
    ];
  }

  Widget _buildTabNavigator(GlobalKey<NavigatorState> key, Widget rootScreen) {
    return Navigator(
      key: key,
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (_) => rootScreen,
        );
      },
    );
  }
}
