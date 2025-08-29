import 'package:arkad_api/arkad_api.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../features/auth/data/data_sources/auth_local_data_source.dart';
import '../features/auth/data/data_sources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/use_cases/complete_signup_use_case.dart';
import '../features/auth/domain/use_cases/get_current_session_use_case.dart';
import '../features/auth/domain/use_cases/reset_password_use_case.dart';
import '../features/auth/domain/use_cases/sign_in_use_case.dart';
import '../features/auth/domain/use_cases/sign_out_use_case.dart';
import '../features/auth/domain/use_cases/sign_up_use_case.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/profile/data/data_sources/profile_local_data_source.dart';
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/use_cases/get_current_profile_use_case.dart';
import '../features/profile/domain/use_cases/update_profile_use_case.dart';
import '../features/profile/domain/use_cases/upload_cv_use_case.dart';
import '../features/profile/domain/use_cases/upload_profile_picture_use_case.dart';
import '../features/profile/presentation/view_models/profile_view_model.dart';
import '../view_models/company_model.dart';
import '../view_models/student_session_model.dart';
import '../view_models/theme_model.dart';

final GetIt serviceLocator = GetIt.instance;

/// Centrialized initialization of all the services and providers. An alternative to Flutter’s inherited widgets and provides a more decoupled way to access services and providers throughout the app. This abstracts the complexity from lower-level components and avoids the need to pass dependencies down the widget tree.

// We could have used InheritedWidget or riverpod package to handle state, but GetIt with provider is a solid combo to my understanding.
void setupServiceLocator() {
  // Core services
  serviceLocator.registerLazySingleton<ArkadApi>(
    () => ArkadApi(basePathOverride: 'https://staging.backend.arkadtlth.se'),
  );
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  serviceLocator.registerLazySingleton<http.Client>(() => http.Client());

  // Clean architecture features
  _setupAuthFeature();
  _setupProfileFeature();

  // Legacy view models (keeping ThemeModel for now)
  serviceLocator.registerLazySingleton<ThemeModel>(() => ThemeModel());
  serviceLocator.registerLazySingleton<CompanyModel>(() => CompanyModel());
  serviceLocator.registerLazySingleton<StudentSessionModel>(
    () => StudentSessionModel(),
  );
}

/// Setup Auth feature with clean architecture
void _setupAuthFeature() {
  // Data sources
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(serviceLocator<FlutterSecureStorage>()),
  );
  serviceLocator.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(serviceLocator<ArkadApi>()),
  );

  // Repository
  serviceLocator.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      serviceLocator<AuthRemoteDataSource>(),
      serviceLocator<AuthLocalDataSource>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<SignInUseCase>(
    () => SignInUseCase(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<SignUpUseCase>(
    () => SignUpUseCase(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<CompleteSignupUseCase>(
    () => CompleteSignupUseCase(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<ResetPasswordUseCase>(
    () => ResetPasswordUseCase(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<SignOutUseCase>(
    () => SignOutUseCase(serviceLocator<AuthRepository>()),
  );
  serviceLocator.registerLazySingleton<GetCurrentSessionUseCase>(
    () => GetCurrentSessionUseCase(serviceLocator<AuthRepository>()),
  );

  // View model
  serviceLocator.registerLazySingleton<AuthViewModel>(
    () => AuthViewModel(
      signInUseCase: serviceLocator<SignInUseCase>(),
      signUpUseCase: serviceLocator<SignUpUseCase>(),
      completeSignupUseCase: serviceLocator<CompleteSignupUseCase>(),
      resetPasswordUseCase: serviceLocator<ResetPasswordUseCase>(),
      signOutUseCase: serviceLocator<SignOutUseCase>(),
      getCurrentSessionUseCase: serviceLocator<GetCurrentSessionUseCase>(),
    ),
  );
}

/// Setup Profile feature with clean architecture
void _setupProfileFeature() {
  // Data sources
  serviceLocator.registerLazySingleton<ProfileLocalDataSource>(
    () => ProfileLocalDataSourceImpl(serviceLocator<FlutterSecureStorage>()),
  );
  serviceLocator.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(serviceLocator<ArkadApi>()),
  );

  // Repository
  serviceLocator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      serviceLocator<ProfileRemoteDataSource>(),
      serviceLocator<ProfileLocalDataSource>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetCurrentProfileUseCase>(
    () => GetCurrentProfileUseCase(serviceLocator<ProfileRepository>()),
  );
  serviceLocator.registerLazySingleton<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(serviceLocator<ProfileRepository>()),
  );
  serviceLocator.registerLazySingleton<UploadProfilePictureUseCase>(
    () => UploadProfilePictureUseCase(serviceLocator<ProfileRepository>()),
  );
  serviceLocator.registerLazySingleton<UploadCVUseCase>(
    () => UploadCVUseCase(serviceLocator<ProfileRepository>()),
  );

  // View model
  serviceLocator.registerLazySingleton<ProfileViewModel>(
    () => ProfileViewModel(
      getCurrentProfileUseCase: serviceLocator<GetCurrentProfileUseCase>(),
      updateProfileUseCase: serviceLocator<UpdateProfileUseCase>(),
      uploadProfilePictureUseCase: serviceLocator<UploadProfilePictureUseCase>(),
      uploadCVUseCase: serviceLocator<UploadCVUseCase>(),
    ),
  );
}
