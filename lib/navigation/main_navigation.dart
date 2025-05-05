import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/companies/company_detail_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import 'bottom_navigation.dart';
import 'navigation_history.dart';

/// Main navigation container that handles authenticated and unauthenticated states
/// with bottom navigation and tab-specific navigation stacks.
///
/// This widget is the entry point for all navigation in the app. It manages
/// tab switching, navigation history, and the correct navigator stack for each tab.
class MainNavigation extends StatefulWidget {
  /// Optionally specify the initial route/tab.
  final String? initialRoute;

  const MainNavigation({super.key, this.initialRoute});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final NavigationHistory _navigationHistory = NavigationHistory();

  // Navigator keys for authenticated state tabs
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(), // Companies
    GlobalKey<NavigatorState>(), // Sessions
    GlobalKey<NavigatorState>(), // Events
    GlobalKey<NavigatorState>(), // Map
    GlobalKey<NavigatorState>(), // Profile
  ];

  // Navigator keys for unauthenticated state tabs
  final List<GlobalKey<NavigatorState>> _unauthNavigatorKeys = [
    GlobalKey<NavigatorState>(), // Companies
    GlobalKey<NavigatorState>(), // Map
    GlobalKey<NavigatorState>(), // Login
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

  /// Sets the initial tab index based on the initialRoute.
  /// If the route is not found, defaults to the first tab.
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
            _navigationHistory.push(_currentIndex, items[i].route);
          });
          return;
        }
      }

      // Default to first tab if route not found
      setState(() {
        _currentIndex = 0;
        _navigationHistory.push(_currentIndex, items[0].route);
      });
    }
  }

  /// Handles tab selection in the bottom navigation.
  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final items = isAuthenticated ? _authenticatedItems : _unauthenticatedItems;

    setState(() {
      _currentIndex = index;
      _navigationHistory.push(_currentIndex, items[_currentIndex].route);
    });
  }

  /// Handles back button press and navigation history.
  /// Returns true if the app should exit, false otherwise.
  bool _handleBackNavigation() {
    final isFirstRouteInCurrentTab =
        !_getActiveNavigatorKey().currentState!.canPop();

    if (isFirstRouteInCurrentTab) {
      // If we're at the root of the current tab, try to go back to previous tab
      if (_navigationHistory.hasMultipleEntries) {
        final previousItem = _navigationHistory.pop();
        if (previousItem != null && previousItem.tabIndex != _currentIndex) {
          setState(() {
            _currentIndex = previousItem.tabIndex;
          });
          return false; // Don't exit the app
        }
      }
      // If no more history or it's the same tab, allow the app to exit
      return true;
    }

    // Let the tab's Navigator handle the back button
    _getActiveNavigatorKey().currentState!.pop();

    // Update navigation history after popping
    _updateHistoryOnTabPop();

    return false; // Don't exit the app
  }

  /// Updates the navigation history when popping a screen within a tab.
  void _updateHistoryOnTabPop() {
    final navKey = _getActiveNavigatorKey();
    if (navKey.currentState != null && navKey.currentState!.canPop()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final items =
          isAuthenticated ? _authenticatedItems : _unauthenticatedItems;

      // Update history with the tab's base route
      _navigationHistory.push(_currentIndex, items[_currentIndex].route);
    }
  }

  /// Gets the active navigator key for the current tab.
  GlobalKey<NavigatorState> _getActiveNavigatorKey() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final navigatorKeys =
        isAuthenticated ? _navigatorKeys : _unauthNavigatorKeys;
    return navigatorKeys[_currentIndex];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isAuthenticated = authProvider.isAuthenticated;
    final items = isAuthenticated ? _authenticatedItems : _unauthenticatedItems;
    final navigatorKeys =
        isAuthenticated ? _navigatorKeys : _unauthNavigatorKeys;

    // Reset index if it's out of range (e.g., after logging out)
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
      _navigationHistory.clear();
      _navigationHistory.push(0, items[0].route);
    }

    return WillPopScope(
      onWillPop: () async {
        return _handleBackNavigation();
      },
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Use a ConstrainedBox to ensure the body never overflows
            return Scaffold(
              resizeToAvoidBottomInset: true,
              body: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                  maxHeight: constraints.maxHeight,
                ),
                child: IndexedStack(
                  index: _currentIndex,
                  children: isAuthenticated
                      ? _buildAuthenticatedTabNavigators(navigatorKeys)
                      : _buildUnauthenticatedTabNavigators(navigatorKeys),
                ),
              ),
              bottomNavigationBar: authProvider.status != AuthStatus.initial
                  ? AppBottomNavigation(
                      currentIndex: _currentIndex,
                      onTap: _onTabTapped,
                      items: items,
                    )
                  : null,
            );
          },
        ),
      ),
    );
  }

  /// Builds navigator stacks for authenticated state.
  List<Widget> _buildAuthenticatedTabNavigators(
      List<GlobalKey<NavigatorState>> keys) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return [
      _buildTabNavigator(keys[0], 'companies', const CompaniesScreen()),
      _buildTabNavigator(keys[1], 'sessions', const StudentSessionsScreen()),
      _buildTabNavigator(keys[2], 'events', const EventScreen()),
      _buildTabNavigator(keys[3], 'map', const MapScreen()),
      _buildTabNavigator(
          keys[4], 'profile', ProfileScreen(user: authProvider.user!)),
    ];
  }

  /// Builds navigator stacks for unauthenticated state.
  List<Widget> _buildUnauthenticatedTabNavigators(
      List<GlobalKey<NavigatorState>> keys) {
    return [
      _buildTabNavigator(keys[0], 'companies', const CompaniesScreen()),
      _buildTabNavigator(keys[1], 'map', const MapScreen()),
      _buildTabNavigator(keys[2], 'auth', const LoginScreen()),
    ];
  }

  /// Creates a nested Navigator for each tab with its own navigation stack.
  Widget _buildTabNavigator(
      GlobalKey<NavigatorState> key, String tabId, Widget rootScreen) {
    return Navigator(
      key: key,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        Widget screen;

        if (settings.name == '/') {
          screen = rootScreen;
        } else {
          screen = _buildScreenForRoute(tabId, settings);
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) => screen,
        );
      },
    );
  }

  /// Resolves the appropriate screen for a given route within a tab.
  Widget _buildScreenForRoute(String tabId, RouteSettings settings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final uri = Uri.parse(settings.name!);
    final pathSegments = uri.pathSegments;

    // Handle routes for each tab
    switch (tabId) {
      case 'companies':
        if (pathSegments.length > 1 && pathSegments[1] == 'detail') {
          final arguments = settings.arguments as Map<String, dynamic>?;
          final company = arguments?['company'];
          if (company != null) {
            return CompanyDetailScreen(company: company);
          }
        }
        return const CompaniesScreen();

      case 'profile':
        if (pathSegments.length > 1 && pathSegments[1] == 'edit') {
          return EditProfileScreen(user: authProvider.user!);
        }
        return ProfileScreen(user: authProvider.user!);

      case 'auth':
        if (pathSegments.length > 1) {
          switch (pathSegments[1]) {
            case 'signup':
              return const SignupScreen();
            case 'verification':
              final arguments = settings.arguments as Map<String, dynamic>?;
              final email = arguments?['email'] as String? ?? '';
              return VerificationScreen(email: email);
            case 'reset-password':
              return const ResetPasswordScreen();
          }
        }
        return const LoginScreen();

      case 'map':
        return const MapScreen();

      case 'sessions':
        return const StudentSessionsScreen();

      case 'events':
        return const EventScreen();

      default:
        return const Scaffold(
          body: Center(child: Text('Route not found')),
        );
    }
  }
}
