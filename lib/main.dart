import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/app_router.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'services/service_locator.dart';

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

  @override
  void initState() {
    super.initState();
    // Grab the AuthProvider (already registered as singleton in serviceLocator)
    final auth = serviceLocator<AuthProvider>();
    _appRouter = AppRouter(auth); // only once, here
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serviceLocator<ThemeProvider>()),
        ChangeNotifierProvider.value(value: serviceLocator<AuthProvider>()),
        ChangeNotifierProvider.value(
            value: serviceLocator<ProfileOnboardingProvider>()),
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
