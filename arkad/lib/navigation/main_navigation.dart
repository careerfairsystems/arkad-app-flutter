import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'bottom_navigation.dart';
import 'navigation_history.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/companies/company_detail_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';

class MainNavigation extends StatefulWidget {
  final String? initialRoute;

  const MainNavigation({Key? key, this.initialRoute}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final NavigationHistory _navigationHistory = NavigationHistory();

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
            // Add initial route to navigation history
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

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isAuthenticated = authProvider.isAuthenticated;
    final items = isAuthenticated ? _authenticatedItems : _unauthenticatedItems;

    setState(() {
      _currentIndex = index;
      // Add new tab to navigation history
      _navigationHistory.push(_currentIndex, items[_currentIndex].route);
    });
  }

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
          return false;
        }
      }
      // If we have no more items in history or it's the same tab, allow the app to exit
      return true;
    }

    // Otherwise let the tab's Navigator handle the back button
    _getActiveNavigatorKey().currentState!.pop();

    // Update navigation history to track route pops within tab
    _updateHistoryOnTabPop();

    return false;
  }

  // New method to update history when popping within a tab
  void _updateHistoryOnTabPop() {
    final navKey = _getActiveNavigatorKey();
    if (navKey.currentState != null && navKey.currentState!.canPop()) {
      // We can't directly get the new current route after popping,
      // so we'll just record that we're still in this tab but at a different route
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final isAuthenticated = authProvider.isAuthenticated;
      final items =
          isAuthenticated ? _authenticatedItems : _unauthenticatedItems;

      // Just push the tab's base route again to update history
      _navigationHistory.push(_currentIndex, items[_currentIndex].route);
    }
  }

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

    // Reset index if it's out of range (e.g. after logging out)
    if (_currentIndex >= items.length) {
      _currentIndex = 0;
      // Reset navigation history if authentication state changed
      _navigationHistory.clear();
      _navigationHistory.push(0, items[0].route);
    }

    return WillPopScope(
      onWillPop: () async {
        return _handleBackNavigation();
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
      _buildTabNavigator(keys[0], 'companies', const CompaniesScreen()),
      _buildTabNavigator(keys[1], 'sessions', const StudentSessionsScreen()),
      _buildTabNavigator(keys[2], 'events', const EventScreen()),
      _buildTabNavigator(keys[3], 'map', const MapScreen()),
      _buildTabNavigator(
          keys[4], 'profile', ProfileScreen(user: authProvider.user!)),
    ];
  }

  List<Widget> _buildUnauthenticatedTabNavigators(
      List<GlobalKey<NavigatorState>> keys) {
    return [
      _buildTabNavigator(keys[0], 'companies', const CompaniesScreen()),
      _buildTabNavigator(keys[1], 'map', const MapScreen()),
      _buildTabNavigator(keys[2], 'auth', const LoginScreen()),
    ];
  }

  // Updated method to handle routes within each tab
  Widget _buildTabNavigator(
      GlobalKey<NavigatorState> key, String tabId, Widget rootScreen) {
    return Navigator(
      key: key,
      initialRoute: '/',
      onGenerateRoute: (RouteSettings settings) {
        Widget screen;

        // Handle the initial route
        if (settings.name == '/') {
          screen = rootScreen;
        } else {
          // Handle specific routes based on tab and route path
          screen = _buildScreenForRoute(tabId, settings);
        }

        // Return the appropriate route with the screen
        return MaterialPageRoute(
          settings: settings,
          builder: (BuildContext context) => screen,
        );
      },
    );
  }

  // New method to build screens for each route within tabs
  Widget _buildScreenForRoute(String tabId, RouteSettings settings) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Split the route path to get components
    final uri = Uri.parse(settings.name!);
    final pathSegments = uri.pathSegments;

    // Handle routes for each tab
    switch (tabId) {
      case 'companies':
        if (pathSegments.length > 1 && pathSegments[1] == 'detail') {
          // Get company ID from arguments
          final arguments = settings.arguments as Map<String, dynamic>?;
          final companyId = arguments?['companyId'] as int?;
          if (companyId != null) {
            // Fetch the company and return the detail screen
            final companyService = Provider.of(context, listen: false);
            final company = companyService.getCompanyById(companyId);
            if (company != null) {
              return CompanyDetailScreen(company: company);
            }
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

      // Add cases for other tabs as needed

      default:
        // Default fallback - should not happen in normal flow
        return const Scaffold(
          body: Center(child: Text('Route not found')),
        );
    }
  }
}
