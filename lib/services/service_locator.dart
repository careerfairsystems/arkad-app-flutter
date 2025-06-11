import 'package:arkad/services/company_service.dart';
import 'package:arkad/view_models/auth_model.dart';
import 'package:arkad/view_models/profile_model.dart';
import 'package:arkad/view_models/theme_model.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/theme_provider.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'company_service.dart';
import 'user_service.dart';

final GetIt serviceLocator = GetIt.instance;

/// Centrialized initialization of all the services and providers. An alternative to Flutter’s inherited widgets and provides a more decoupled way to access services and providers throughout the app. This abstracts the complexity from lower-level components and avoids the need to pass dependencies down the widget tree.

// We could have used InheritedWidget or riverpod package to handle state, but GetIt with provider is a solid combo to my understanding.
void setupServiceLocator() {
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  serviceLocator.registerLazySingleton<http.Client>(() => http.Client());

  serviceLocator.registerLazySingleton<ArkadApi>(
    () => ArkadApi(basePathOverride: 'https://staging.backend.arkadtlth.se'),
  );

  serviceLocator.registerSingleton(AuthModel);

  serviceLocator.registerLazySingleton<ThemeModel>(() => ThemeModel());
  serviceLocator.registerLazySingleton<CompanyService>(() => CompanyService());

  serviceLocator.registerLazySingleton<ProfileModel>(() => ProfileModel());
}
