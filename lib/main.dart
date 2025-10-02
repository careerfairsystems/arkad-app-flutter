import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/company/presentation/view_models/company_detail_view_model.dart';
import 'features/company/presentation/view_models/company_view_model.dart';
import 'features/event/presentation/view_models/event_view_model.dart';
import 'features/map/presentation/view_models/map_view_model.dart';
import 'features/notifications/presentation/view_models/notification_view_model.dart';
import 'features/profile/presentation/view_models/profile_view_model.dart';
import 'features/student_session/presentation/view_models/student_session_view_model.dart';
import 'navigation/app_router.dart';
import 'navigation/router_notifier.dart';
import 'services/service_locator.dart';
import 'shared/presentation/themes/providers/theme_provider.dart';

void main() async {
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://a42d50c4a8a0196fd8b2ace3397d6b3d@o4506696085340160.ingest.us.sentry.io/4509367674142720';
      // Adds request headers and IP for users, for more info visit:
      // https://docs.sentry.io/platforms/dart/guides/flutter/data-management/data-collected/
      options.sendDefaultPii = true;
      options.enableLogs = true;
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      // Configure Session Replay
      options.replay.sessionSampleRate = 0.1;
      options.replay.onErrorSampleRate = 1.0;
    },
    appRunner: () async {
      // Ensure that the Flutter engine is initialized before running the app
      WidgetsFlutterBinding.ensureInitialized();

      // Initialize the GetIt.instance, a singleton instance of the service locator
      setupServiceLocator();

      runApp(SentryWidget(child: const MyApp()));
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppRouter _appRouter;
  late final RouterNotifier _routerNotifier;

  @override
  void initState() {
    super.initState();
    // Use clean architecture: AuthViewModel → RouterNotifier → AppRouter
    final authViewModel = serviceLocator<AuthViewModel>();
    _routerNotifier = RouterNotifier(authViewModel);
    _appRouter = AppRouter(_routerNotifier);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Shared providers
        ChangeNotifierProvider.value(value: serviceLocator<ThemeProvider>()),

        // Clean architecture view models
        ChangeNotifierProvider.value(value: serviceLocator<AuthViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<ProfileViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<CompanyViewModel>()),
        ChangeNotifierProvider.value(
          value: serviceLocator<CompanyDetailViewModel>(),
        ),
        ChangeNotifierProvider.value(
          value: serviceLocator<StudentSessionViewModel>(),
        ),
        ChangeNotifierProvider.value(value: serviceLocator<EventViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<MapViewModel>()),
        ChangeNotifierProvider.value(
          value: serviceLocator<NotificationViewModel>(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (ctx, themeProvider, _) {
          return MaterialApp.router(
            title: 'Arkad App',
            theme: themeProvider.getTheme(),
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
