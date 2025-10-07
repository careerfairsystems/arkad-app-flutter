import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/reset_password_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/auth/presentation/screens/verification_screen.dart';
import '../features/company/presentation/screens/companies_screen.dart';
import '../features/company/presentation/screens/company_detail_screen.dart';
import '../features/event/presentation/screens/event_attendees_wrapper.dart';
import '../features/event/presentation/screens/event_detail_screen.dart';
import '../features/event/presentation/screens/event_screen.dart';
import '../features/event/presentation/screens/event_ticket_screen.dart';
import '../features/event/presentation/screens/scan_event_screen.dart';
import '../features/map/presentation/screens/map_screen.dart';
import '../features/profile/presentation/screens/edit_profile_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../features/student_session/domain/entities/student_session.dart';
import '../features/student_session/presentation/screens/student_session_application_form_screen.dart';
import '../features/student_session/presentation/screens/student_session_time_selection.dart';
import '../features/student_session/presentation/screens/student_sessions_screen.dart';
import '../widgets/app_bottom_navigation.dart';
import 'navigation_items.dart';
import 'router_notifier.dart';

class AppRouter {
  AppRouter(this._routerNotifier);

  final RouterNotifier _routerNotifier;

  // ────────────────────────────────────────────────────────────
  // Redirect rules
  // ────────────────────────────────────────────────────────────
  String? _redirect(BuildContext context, GoRouterState state) {
    final loggedIn = _routerNotifier.isAuthenticated;
    final isInitializing = _routerNotifier.isInitializing;
    final path = state.uri.path;

    // Wait for auth initialization to complete
    if (isInitializing) return null;

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
    refreshListenable: _routerNotifier,
    redirect: _redirect,
    initialLocation: '/companies',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _AppBottomNavShell(
          navigationShell: shell,
          isAuthenticated: _routerNotifier.isAuthenticated,
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
                    path: 'detail/:id',
                    pageBuilder: _slide((context, s) {
                      final idStr = s.pathParameters['id'];
                      final companyId = int.tryParse(idStr ?? '');
                      if (companyId == null) {
                        return const Scaffold(
                          body: Center(
                            child: Text('Error: Invalid company ID'),
                          ),
                        );
                      }
                      return CompanyDetailScreen(companyId: companyId);
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
                  final companyId = state
                      .pathParameters["companyId"]!; // Get "id" param from URL
                  return StudentSessionApplicationFormScreen(
                    companyId: companyId,
                  );
                },
              ),
              GoRoute(
                path: '/sessions/apply/:companyId',
                builder: (context, state) {
                  final companyId = state
                      .pathParameters["companyId"]!; // Get "id" param from URL
                  return StudentSessionTimeSelectionScreen(id: companyId);
                },
              ),
              GoRoute(
                path: '/sessions/book/:companyId',
                builder: (context, state) {
                  final companyId = state.pathParameters["companyId"]!;
                  return StudentSessionTimeSelectionScreen(
                    id: companyId,
                    isBookingMode:
                        true, // Flag to indicate this is for booking, not applying
                  );
                },
              ),
              GoRoute(
                path: '/sessions/application-form/:companyId',
                builder: (context, state) {
                  final session = state.extra as StudentSession?;
                  final companyId = state.pathParameters["companyId"]!;
                  return StudentSessionApplicationFormScreen(
                    session: session,
                    companyId: companyId,
                  );
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
                routes: [
                  GoRoute(
                    path: 'scan/:eventId',
                    pageBuilder: _slide((context, s) {
                      final eventIdStr = s.pathParameters['eventId'];
                      final eventId = int.tryParse(eventIdStr ?? '');
                      if (eventId == null) {
                        return const Scaffold(
                          body: Center(child: Text('Error: Invalid event ID')),
                        );
                      }
                      return ScanEventScreen(eventId: eventId);
                    }),
                  ),
                  GoRoute(
                    path: 'detail/:id',
                    pageBuilder: _slide((context, s) {
                      final idStr = s.pathParameters['id'];

                      final eventId = int.tryParse(idStr ?? '');

                      if (eventId == null) {
                        print(
                          '   ❌ Failed to parse event ID - showing error screen',
                        );
                        return const Scaffold(
                          body: Center(child: Text('Error: Invalid event ID')),
                        );
                      }
                      if (kDebugMode) {
                        debugPrint(
                          '   Creating EventDetailScreen with ID=$eventId',
                        );
                      }
                      return EventDetailScreen(eventId: eventId);
                    }),
                    routes: [
                      GoRoute(
                        path: 'ticket',
                        pageBuilder: _slide((context, s) {
                          final idStr = s.pathParameters['id'];
                          final eventId = int.tryParse(idStr ?? '');
                          if (eventId == null) {
                            return const Scaffold(
                              body: Center(
                                child: Text('Error: Invalid event ID'),
                              ),
                            );
                          }
                          return EventTicketScreen(eventId: eventId);
                        }),
                      ),
                      GoRoute(
                        path: 'attendees',
                        pageBuilder: _slide((context, s) {
                          final idStr = s.pathParameters['id'];
                          final eventId = int.tryParse(idStr ?? '');
                          if (eventId == null) {
                            return const Scaffold(
                              body: Center(
                                child: Text('Error: Invalid event ID'),
                              ),
                            );
                          }
                          // We need to get the event object somehow
                          // For now, we'll need to fetch it in the screen
                          return EventAttendeesWrapper(eventId: eventId);
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          // Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                pageBuilder: _noAnim((context) {
                  return const ProfileScreen();
                }),
                routes: [
                  GoRoute(
                    path: 'edit',
                    pageBuilder: _slide((context, _) {
                      return const EditProfileScreen();
                    }),
                  ),
                ],
              ),
            ],
          ),

          // AUTH FLOW (as bottom navigation tab)
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
                  return const VerificationScreen();
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
        builder: (ctx, state) =>
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
) =>
    (context, state) => NoTransitionPage(child: builder(context));

Page<dynamic> Function(BuildContext, GoRouterState) _fade(
  Widget Function(BuildContext) builder,
) =>
    (context, state) => CustomTransitionPage(
      child: builder(context),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    );

Page<dynamic> Function(BuildContext, GoRouterState) _slide(
  Widget Function(BuildContext, GoRouterState) builder,
) =>
    (context, state) => CustomTransitionPage(
      child: builder(context, state),
      transitionsBuilder: (_, anim, __, child) => SlideTransition(
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
        onTap: (i) {
          final targetBranchIndex = items[i].branchIndex;
          if (targetBranchIndex == navigationShell.currentIndex) {
            // Reselecting current tab - reset to initial location
            navigationShell.goBranch(targetBranchIndex, initialLocation: true);
          } else {
            // Switching to different tab - preserve state
            navigationShell.goBranch(targetBranchIndex);
          }
        },
      ),
    );
  }
}
