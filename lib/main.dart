import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/auth/presentation/view_models/auth_view_model.dart';
import 'features/profile/presentation/view_models/profile_view_model.dart';
import 'navigation/app_router.dart';
import 'services/service_locator.dart';
import 'view_models/auth_model.dart';
import 'view_models/company_model.dart';
import 'view_models/profile_model.dart';
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

  @override
  void initState() {
    super.initState();
    // Grab the AuthProvider (already registered as singleton in serviceLocator)
    final auth = serviceLocator<AuthModel>();
    _appRouter = AppRouter(auth); // only once, here
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: serviceLocator<ThemeModel>()),
        // Legacy models (TODO: Remove after migration)
        ChangeNotifierProvider.value(value: serviceLocator<AuthModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<CompanyModel>()),
        ChangeNotifierProvider.value(value: serviceLocator<ProfileModel>()),
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
