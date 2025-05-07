import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/company.dart';
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
import '../widgets/app_bottom_navigation.dart';
import 'navigation_items.dart';

class AppRouter {
  AppRouter(this._auth);

  final AuthProvider _auth;

  // ────────────────────────────────────────────────────────────
  // Redirect rules
  // ────────────────────────────────────────────────────────────
  String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = _auth.isAuthenticated;
    final path = state.uri.path; // e.g. /auth/login
    final inAuthFlow = path.startsWith('/auth');

    if (!loggedIn) {
      // Allow public pages and auth flow
      if (inAuthFlow || _isPublic(path)) return null;
      // Anything else is protected
      return '/auth/login';
    }

    // If logged‑in but still on auth pages → bounce to main tab
    if (inAuthFlow) return '/companies';
    return null;
  }

  bool _isPublic(String path) => ['/companies', '/map', '/auth']
      .any((p) => path == p || path.startsWith('$p/'));

  // ────────────────────────────────────────────────────────────
  // GoRouter
  // ────────────────────────────────────────────────────────────
  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: _auth,
    redirect: _redirect,
    initialLocation: '/companies',
    routes: [
      // ── STATEFUL SHELL WITH 6 FIXED BRANCHES ───────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppBottomNavShell(
          navigationShell: shell,
          isAuthenticated: _auth.isAuthenticated,
        ),
        branches: [
          // 0 ▸ Companies
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/companies',
                pageBuilder: _noAnim((_) => const CompaniesScreen()),
                routes: [
                  GoRoute(
                    path: 'detail',
                    pageBuilder: _slide((context, s) {
                      final company = s.extra as Company?;
                      if (company == null) {
                        return const Scaffold(
                          body: Center(child: Text('Error: company missing')),
                        );
                      }
                      return CompanyDetailScreen(company: company);
                    }),
                  ),
                ],
              ),
            ],
          ),

          // 1 ▸ Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                pageBuilder: _noAnim((_) => const MapScreen()),
              ),
            ],
          ),

          // 2 ▸ Sessions (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sessions',
                pageBuilder: _noAnim((_) => const StudentSessionsScreen()),
              ),
            ],
          ),

          // 3 ▸ Events (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                pageBuilder: _noAnim((_) => const EventScreen()),
              ),
            ],
          ),

          // 4 ▸ Profile (protected)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: _noAnim((context) {
                  final user = context.read<AuthProvider>().user!;
                  return ProfileScreen(user: user);
                }),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: _slide((context, _) {
                      final user = context.read<AuthProvider>().user!;
                      return EditProfileScreen(user: user);
                    }),
                  ),
                ],
              ),
            ],
          ),

          // 5 ▸ AUTH FLOW  (public, but still inside the shell → bottom bar stays)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/auth/login',
                pageBuilder: _fade((_) => const LoginScreen()),
              ),
              GoRoute(
                path: '/auth/signup',
                pageBuilder: _slide((context, _) => const SignupScreen()),
              ),
              GoRoute(
                path: '/auth/verification',
                pageBuilder: _slide((context, s) {
                  final email = s.uri.queryParameters['email'] ?? '';
                  return VerificationScreen(email: email);
                }),
              ),
              GoRoute(
                path: '/auth/reset-password',
                pageBuilder:
                    _slide((context, _) => const ResetPasswordScreen()),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

// ──────────────────────────────────────────────────────────────
// Page‑builder helpers
// ──────────────────────────────────────────────────────────────
Page<dynamic> Function(BuildContext, GoRouterState) _noAnim(
        Widget Function(BuildContext) builder) =>
    (context, state) => NoTransitionPage(child: builder(context));

Page<dynamic> Function(BuildContext, GoRouterState) _fade(
        Widget Function(BuildContext) builder) =>
    (context, state) => CustomTransitionPage(
          child: builder(context),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        );

Page<dynamic> Function(BuildContext, GoRouterState) _slide(
        Widget Function(BuildContext, GoRouterState) builder) =>
    (context, state) => CustomTransitionPage(
          child: builder(context, state),
          transitionsBuilder: (_, anim, __, child) => SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: Offset.zero)
                .animate(anim),
            child: child,
          ),
        );

// ──────────────────────────────────────────────────────────────
// Bottom‑navigation shell
// ──────────────────────────────────────────────────────────────
class _AppBottomNavShell extends StatelessWidget {
  const _AppBottomNavShell({
    required this.navigationShell,
    required this.isAuthenticated,
  });

  final StatefulNavigationShell navigationShell;
  final bool isAuthenticated;

  @override
  Widget build(BuildContext context) {
    final items = NavigationItems.forAuth(isAuthenticated);

    // Map the shell branch → visible tab index
    final tabIndex = items.indexWhere(
      (item) => item.branchIndex == navigationShell.currentIndex,
    );

    // If current branch isn’t in the visible list (e.g., after login/logout)
    final safeTabIndex = tabIndex >= 0 ? tabIndex : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: safeTabIndex,
        items: items,
        onTap: (i) => navigationShell.goBranch(
          items[i].branchIndex,
          initialLocation: true,
        ),
      ),
    );
  }
}
