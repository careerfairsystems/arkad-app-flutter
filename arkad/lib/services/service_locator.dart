import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'user_service.dart';
import 'company_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Initialize all the services and providers at app startup
void setupServiceLocator() {
  // Register dependencies
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage());
  serviceLocator.registerLazySingleton<http.Client>(() => http.Client());

  // Register services with their dependencies
  serviceLocator.registerLazySingleton<ApiService>(
    () => ApiService(client: serviceLocator<http.Client>()),
  );

  serviceLocator.registerLazySingleton<AuthService>(
    () => AuthService(
      storage: serviceLocator<FlutterSecureStorage>(),
      apiService: serviceLocator<ApiService>(),
    ),
  );

  serviceLocator.registerLazySingleton<UserService>(
    () => UserService(
      authService: serviceLocator<AuthService>(),
      apiService: serviceLocator<ApiService>(),
    ),
  );

  serviceLocator.registerLazySingleton<CompanyService>(
    () => CompanyService(
      authService: serviceLocator<AuthService>(),
      apiService: serviceLocator<ApiService>(),
    ),
  );

  // Register providers
  serviceLocator.registerLazySingleton<AuthProvider>(
    () => AuthProvider(
      serviceLocator<AuthService>(),
      serviceLocator<UserService>(),
    ),
  );

  serviceLocator.registerLazySingleton<ThemeProvider>(
    () => ThemeProvider(),
  );

  // Initialize providers that need immediate initialization
  serviceLocator<AuthProvider>().init();
}
