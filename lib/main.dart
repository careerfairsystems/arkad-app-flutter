import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/profile/presentation/view_models/profile_view_model.dart';
import 'navigation/app_router.dart';
import 'navigation/router_notifier.dart';
import 'services/service_locator.dart';
import 'view_models/company_model.dart';
import 'view_models/student_session_model.dart';
import 'view_models/theme_model.dart';

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
        ChangeNotifierProvider.value(value: serviceLocator<ThemeModel>()),
        // Legacy models (TODO: Migrate to clean architecture)
        ChangeNotifierProvider.value(value: serviceLocator<CompanyModel>()),
        ChangeNotifierProvider.value(
          value: serviceLocator<StudentSessionModel>(),
        ),
        // Clean architecture view models
        ChangeNotifierProvider.value(value: serviceLocator<AuthViewModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<ProfileViewModel>()),
      ],
      child: Consumer<ThemeModel>(
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
