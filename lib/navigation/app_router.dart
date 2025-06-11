import 'package:arkad/view_models/auth_model.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
import '../screens/student_sessions/student_sessions_form.dart';
import '../screens/student_sessions/student_session_time_selection.dart';
import '../screens/student_sessions/student_sessions_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import 'navigation_items.dart';

class AppRouter {
  AppRouter(this._auth);

  final AuthModel _auth;

  // ────────────────────────────────────────────────────────────
  // Redirect rules
  // ────────────────────────────────────────────────────────────
  String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = _auth.isAuthenticated;
    final path = state.uri.path;

    const publicPrefixes = [
      '/companies',
      '/map',
      '/auth',
      '/sessions',
      '/events',
    ];

    bool isPublic(String path) =>
        publicPrefixes.any((base) => path == base || path.startsWith('$base/'));

    // Redirect to login if trying to access profile while not authenticated
    if (!loggedIn && path.startsWith('/profile')) return '/auth/login';

    // For other protected routes (if any), redirect to login
    if (!loggedIn && !isPublic(path)) return '/auth/login';

    return null;
  }

  // ────────────────────────────────────────────────────────────
  // GoRouter
  // ────────────────────────────────────────────────────────────
  late final GoRouter router = GoRouter(
    debugLogDiagnostics: true,
    refreshListenable: _auth.authState,
    redirect: _redirect,
    initialLocation: '/companies',
    routes: [
      StatefulShellRoute.indexedStack(
        builder:
            (context, state, shell) => _AppBottomNavShell(
              navigationShell: shell,
              isAuthenticated: _auth.isAuthenticated,
            ),
        branches: [
          // Companies
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/companies',
                pageBuilder: _noAnim((_) => const CompaniesScreen()),
                routes: [
                  GoRoute(
                    path: 'detail',
                    pageBuilder: _slide((context, s) {
                      final company = s.extra as CompanyOut?;
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

          // Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                pageBuilder: _noAnim((_) => const MapScreen()),
              ),
            ],
          ),

          // Sessions
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sessions',
                pageBuilder: _noAnim((_) => const StudentSessionsScreen()),
              ),
              GoRoute(
                path: '/sessions/form/:companyId',
                builder: (context, state) {
                  final companyId =
                      state
                          .pathParameters["companyId"]!; // Get "id" param from URL
                  return StudentSessionFormScreen(id: companyId);
                },
              ),
              GoRoute(
                path: '/sessions/apply/:companyId',
                builder: (context, state) {
                  final companyId =
                      state
                          .pathParameters["companyId"]!; // Get "id" param from URL
                  return StudentSessionTimeSelectionScreen(id: companyId);
                },
              ),
            ],
          ),

          // Events
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                pageBuilder: _noAnim((_) => const EventScreen()),
              ),
            ],
          ),

          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: _noAnim((context) {
                  final user = context.read<AuthModel>().user!;
                  return ProfileScreen(profile: user);
                }),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: _slide((context, _) {
                      final user = context.read<AuthModel>().user!;
                      return EditProfileScreen(profile: user);
                    }),
                  ),
                ],
              ),
            ],
          ),

          // AUTH FLOW
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
                pageBuilder: _slide(
                  (context, _) => const ResetPasswordScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/:_(.*)',
        builder:
            (ctx, state) =>
                const Scaffold(body: Center(child: Text('Page not found'))),
      ),
    ],
  );
}

// ──────────────────────────────────────────────────────────────
// Page‑builder helpers
// ──────────────────────────────────────────────────────────────
Page<dynamic> Function(BuildContext, GoRouterState) _noAnim(
  Widget Function(BuildContext) builder,
) => (context, state) => NoTransitionPage(child: builder(context));

Page<dynamic> Function(BuildContext, GoRouterState) _fade(
  Widget Function(BuildContext) builder,
) =>
    (context, state) => CustomTransitionPage(
      child: builder(context),
      transitionsBuilder:
          (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
    );

Page<dynamic> Function(BuildContext, GoRouterState) _slide(
  Widget Function(BuildContext, GoRouterState) builder,
) =>
    (context, state) => CustomTransitionPage(
      child: builder(context, state),
      transitionsBuilder:
          (_, anim, __, child) => SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(anim),
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
        onTap:
            (i) => navigationShell.goBranch(
              items[i].branchIndex,
              initialLocation: true,
            ),
      ),
    );
  }
}
