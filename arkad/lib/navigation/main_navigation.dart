import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../providers/auth_provider.dart';
import 'bottom_navigation.dart';

class MainNavigation extends StatefulWidget {
  final String? initialRoute;

  const MainNavigation({Key? key, this.initialRoute}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Screens without authentication requirement
  final List<Widget> _publicScreens = [
    const CompaniesScreen(),
    const StudentSessionsScreen(),
    const EventScreen(),
    const MapScreen(),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      switch (widget.initialRoute) {
        case '/companies':
          _currentIndex = 0;
          break;
        case '/sessions':
          _currentIndex = 1;
          break;
        case '/events':
          _currentIndex = 2;
          break;
        case '/map':
          _currentIndex = 3;
          break;
        case '/profile':
          _currentIndex = 4;
          break;
      }
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

    // If user is trying to access profile but is not authenticated
    if (_currentIndex == 4 && authProvider.user == null) {
      // Redirect to login screen without changing the current index state
      return const LoginScreen();
    }

    // All screens including the profile screen
    final List<Widget> _allScreens = [
      ..._publicScreens,
      // Profile screen - only rendered when actually used to prevent premature user fetch
      if (_currentIndex == 4 && authProvider.user != null)
        ProfileScreen(user: authProvider.user!)
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex < _allScreens.length ? _currentIndex : 0,
        children: _allScreens,
      ),
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
