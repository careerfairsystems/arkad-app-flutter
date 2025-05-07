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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use providers from the service locator, but wrap them with ChangeNotifierProvider
    // so the widgets can still consume them using Provider.of<T>
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serviceLocator<ThemeProvider>()),
        ChangeNotifierProvider.value(value: serviceLocator<AuthProvider>()),
        // Use the singleton instance from service locator
        ChangeNotifierProvider.value(
            value: serviceLocator<ProfileOnboardingProvider>()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, themeProvider, auth, _) {
          // Create a new AppRouter instance with auth
          final router = AppRouter(auth).router;
          return MaterialApp.router(
            title: 'Arkad App',
            theme: themeProvider.getTheme(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
