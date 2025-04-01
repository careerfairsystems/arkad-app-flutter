import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'navigation/main_navigation.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize any services that need to be set up before the app starts

  runApp(
    MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            Provider.of<AuthService>(context, listen: false),
            Provider.of<UserService>(context, listen: false),
          )..init(),
        ),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        // ...other providers
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Arkad App',
      theme: themeProvider.getTheme(),
      home: const MainNavigation(initialRoute: '/companies'),
      // Using the MainNavigation widget for navigation instead of routes
    );
  }
}
