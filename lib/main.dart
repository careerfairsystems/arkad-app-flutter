import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/company/presentation/view_models/company_detail_view_model.dart';
import 'features/company/presentation/view_models/company_view_model.dart';
import 'features/profile/presentation/view_models/profile_view_model.dart';
import 'navigation/app_router.dart';
import 'navigation/router_notifier.dart';
import 'services/service_locator.dart';
import 'features/event/presentation/view_models/event_view_model.dart';
import 'features/map/presentation/view_models/map_view_model.dart';
import 'features/student_session/presentation/view_models/student_session_view_model.dart';
import 'shared/presentation/themes/providers/theme_provider.dart';

void main() async {
  // Good pratice, harmless to include. Ensure that the Flutter engine is initialized before running the app. In simplier terms if you need to do any native setup or asynchronous work such as reading local storage before showing the UI, this call ensures that the Flutter engine is ready to handle it.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the GetIt.instance, a singleton instance of the service locator that is globally accessible and hold references to our services, calling getIt<SomeType>() will refer to the same registered objects.
  setupServiceLocator();

  runApp(const MyApp());
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
        ChangeNotifierProvider.value(value: serviceLocator<CompanyDetailViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<StudentSessionViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<EventViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<MapViewModel>()),
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
