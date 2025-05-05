import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'navigation/main_navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_onboarding_provider.dart';
import 'providers/theme_provider.dart';
import 'services/service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the service locator
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
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) => MaterialApp(
          title: 'Arkad App',
          theme: themeProvider.getTheme(),
          home: const MainNavigation(initialRoute: '/companies'),
        ),
      ),
    );
  }
}
