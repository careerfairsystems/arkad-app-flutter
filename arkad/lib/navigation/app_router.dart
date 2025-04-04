import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'main_navigation.dart';
import '../screens/companies/companies_screen.dart';
import '../screens/companies/company_detail_screen.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../screens/event/event_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../providers/auth_provider.dart';
import '../services/company_service.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final pathSegments = uri.pathSegments;

    // Main navigation entry points
    if (pathSegments.isEmpty || pathSegments[0] == 'home') {
      return MaterialPageRoute(
          builder: (_) => const MainNavigation(initialRoute: '/companies'));
    }

    switch (pathSegments[0]) {
      // Main navigation routes
      case 'companies':
        if (pathSegments.length > 1) {
          // Handle company details with ID
          final companyId = int.tryParse(pathSegments[1]);
          if (companyId != null) {
            return MaterialPageRoute(
              builder: (context) {
                final companyService = CompanyService();
                if (companyService.isLoaded) {
                  final company = companyService.getCompanyById(companyId);
                  if (company != null) {
                    return CompanyDetailScreen(company: company);
                  }
                }
                // If company isn't loaded or found, go to companies screen
                return const CompaniesScreen();
              },
            );
          }
        }
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/companies'));

      case 'sessions':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/sessions'));

      case 'events':
        if (pathSegments.length > 1) {
          // Handle event details with ID
          final eventId = pathSegments[1];
          return MaterialPageRoute(builder: (_) => EventScreen());
        }
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/events'));

      case 'map':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/map'));

      case 'profile':
        if (pathSegments.length > 1 && pathSegments[1] == 'edit') {
          return MaterialPageRoute(
            builder: (_) {
              final authProvider = Provider.of<AuthProvider>(_, listen: false);
              return EditProfileScreen(user: authProvider.user!);
            },
          );
        }
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/profile'));

      // Auth related routes
      case 'login':
        return MaterialPageRoute(
            builder: (_) => const MainNavigation(initialRoute: '/login'));

      case 'auth':
        if (pathSegments.length > 1) {
          switch (pathSegments[1]) {
            case 'signup':
              return MaterialPageRoute(builder: (_) => const SignupScreen());
            case 'verification':
              final args = settings.arguments as Map<String, dynamic>?;
              final email = args?['email'] as String? ?? '';
              return MaterialPageRoute(
                  builder: (_) => VerificationScreen(email: email));
            case 'password-reset':
              return MaterialPageRoute(
                  builder: (_) => const ResetPasswordScreen());
          }
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(child: Text('Route not found')),
      ),
    );
  }
}
