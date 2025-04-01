import 'package:flutter/material.dart';
import 'main_navigation.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Main navigation routes
      case '/':
      case '/home':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/companies'));
      case '/companies':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/companies'));
      case '/sessions':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/sessions'));
      case '/events':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/events'));
      case '/map':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/map'));

      // Direct routes (no bottom navigation)
      case '/edit-profile':
        // This route should be handled by your existing edit profile screen
        return MaterialPageRoute(
            builder: (_) => const Scaffold(
                  body: Center(child: Text('Edit Profile Screen')),
                ));

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}
