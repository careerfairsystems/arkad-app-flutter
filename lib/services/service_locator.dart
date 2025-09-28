import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../features/auth/data/data_sources/auth_local_data_source.dart';
import '../features/auth/data/data_sources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/use_cases/complete_signup_use_case.dart';
import '../features/auth/domain/use_cases/get_current_session_use_case.dart';
import '../features/auth/domain/use_cases/resend_verification_use_case.dart';
import '../features/auth/domain/use_cases/reset_password_use_case.dart';
import '../features/auth/domain/use_cases/sign_in_use_case.dart';
import '../features/auth/domain/use_cases/sign_out_use_case.dart';
import '../features/auth/domain/use_cases/sign_up_use_case.dart';
import '../features/auth/presentation/view_models/auth_view_model.dart';
import '../features/company/data/data_sources/company_local_data_source.dart';
import '../features/company/data/data_sources/company_remote_data_source.dart';
import '../features/company/data/mappers/company_mapper.dart';
import '../features/company/data/repositories/company_repository_impl.dart';
import '../features/company/domain/repositories/company_repository.dart';
import '../features/company/domain/use_cases/filter_companies_use_case.dart';
import '../features/company/domain/use_cases/get_companies_use_case.dart';
import '../features/company/domain/use_cases/get_company_by_id_use_case.dart';
import '../features/company/domain/use_cases/search_and_filter_companies_use_case.dart';
import '../features/company/domain/use_cases/search_companies_use_case.dart';
import '../features/company/presentation/commands/filter_companies_command.dart';
import '../features/company/presentation/commands/get_companies_command.dart';
import '../features/company/presentation/commands/get_company_by_id_command.dart';
import '../features/company/presentation/commands/search_and_filter_companies_command.dart';
import '../features/company/presentation/commands/search_companies_command.dart';
import '../features/company/presentation/view_models/company_detail_view_model.dart';
import '../features/company/presentation/view_models/company_view_model.dart';
import '../features/event/data/data_sources/event_remote_data_source.dart';
import '../features/event/data/mappers/event_attendee_mapper.dart';
import '../features/event/data/mappers/event_mapper.dart';
import '../features/event/data/mappers/ticket_verification_mapper.dart';
import '../features/event/data/repositories/event_repository_impl.dart';
import '../features/event/domain/repositories/event_repository.dart';
import '../features/event/presentation/view_models/event_view_model.dart';
import '../features/map/data/repositories/map_repository_impl.dart';
import '../features/map/domain/repositories/map_repository.dart';
import '../features/map/presentation/view_models/map_view_model.dart';
import '../features/profile/data/data_sources/profile_local_data_source.dart';
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/use_cases/delete_cv_use_case.dart';
import '../features/profile/domain/use_cases/delete_profile_picture_use_case.dart';
import '../features/profile/domain/use_cases/get_current_profile_use_case.dart';
import '../features/profile/domain/use_cases/update_profile_use_case.dart';
import '../features/profile/domain/use_cases/upload_cv_use_case.dart';
import '../features/profile/domain/use_cases/upload_profile_picture_use_case.dart';
import '../features/profile/presentation/view_models/profile_view_model.dart';
import '../features/student_session/data/data_sources/student_session_local_data_source.dart';
import '../features/student_session/data/data_sources/student_session_remote_data_source.dart';
import '../features/student_session/data/mappers/student_session_mapper.dart';
import '../features/student_session/data/repositories/student_session_repository_impl.dart';
import '../features/student_session/domain/repositories/student_session_repository.dart';
import '../features/student_session/domain/use_cases/apply_for_session_use_case.dart';
import '../features/student_session/domain/use_cases/cancel_application_use_case.dart';
import '../features/student_session/domain/use_cases/get_student_sessions_use_case.dart';
import '../features/student_session/presentation/view_models/student_session_view_model.dart';
import '../shared/infrastructure/services/file_service.dart';
import '../shared/presentation/themes/providers/theme_provider.dart';

final GetIt serviceLocator = GetIt.instance;

/// Centrialized initialization of all the services and providers. An alternative to Flutter’s inherited widgets and provides a more decoupled way to access services and providers throughout the app. This abstracts the complexity from lower-level components and avoids the need to pass dependencies down the widget tree.

// We could have used InheritedWidget or riverpod package to handle state, but GetIt with provider is a solid combo to my understanding.
void setupServiceLocator() {
  // Core services
  _setupApiClient();
  serviceLocator.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );
  serviceLocator.registerLazySingleton<http.Client>(() => http.Client());

  // Shared services
  serviceLocator.registerLazySingleton<ImagePicker>(() => ImagePicker());
  serviceLocator.registerLazySingleton<FileService>(
    () => FileService(serviceLocator<ImagePicker>()),
  );

  // Clean architecture features
  _setupAuthFeature();
  _setupProfileFeature();
  _setupCompanyFeature();
  _setupStudentSessionFeature();
  _setupEventFeature();
  _setupMapFeature();

  // Shared providers
  serviceLocator.registerLazySingleton<ThemeProvider>(() => ThemeProvider());
}

/// Setup API client conditionally
void _setupApiClient() {
  // Setup Dio first - always available
  final dio = Dio();
  dio.options.baseUrl = 'https://staging.backend.arkadtlth.se';
  serviceLocator.registerLazySingleton<Dio>(() => dio);

  // Try to register API client - will work after generation
  _registerApiClientConditionally();
}

/// Register API client
void _registerApiClientConditionally() {
  serviceLocator.registerLazySingleton<ArkadApi>(
    () => ArkadApi(
      dio: serviceLocator<Dio>(),
      basePathOverride: 'https://staging.backend.arkadtlth.se',
    ),
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
  serviceLocator.registerLazySingleton<ResendVerificationUseCase>(
    () => ResendVerificationUseCase(serviceLocator<AuthRepository>()),
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
      resendVerificationUseCase: serviceLocator<ResendVerificationUseCase>(),
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
  serviceLocator.registerLazySingleton<DeleteProfilePictureUseCase>(
    () => DeleteProfilePictureUseCase(serviceLocator<ProfileRepository>()),
  );
  serviceLocator.registerLazySingleton<DeleteCVUseCase>(
    () => DeleteCVUseCase(serviceLocator<ProfileRepository>()),
  );

  // View model
  serviceLocator.registerLazySingleton<ProfileViewModel>(
    () => ProfileViewModel(
      getCurrentProfileUseCase: serviceLocator<GetCurrentProfileUseCase>(),
      updateProfileUseCase: serviceLocator<UpdateProfileUseCase>(),
      uploadProfilePictureUseCase:
          serviceLocator<UploadProfilePictureUseCase>(),
      uploadCVUseCase: serviceLocator<UploadCVUseCase>(),
      deleteProfilePictureUseCase:
          serviceLocator<DeleteProfilePictureUseCase>(),
      deleteCVUseCase: serviceLocator<DeleteCVUseCase>(),
    ),
  );
}

/// Setup Company feature with clean architecture
void _setupCompanyFeature() {
  // Data sources
  serviceLocator.registerLazySingleton<CompanyRemoteDataSource>(
    () => CompanyRemoteDataSource(serviceLocator<ArkadApi>()),
  );
  serviceLocator.registerLazySingleton<CompanyLocalDataSource>(
    () => CompanyLocalDataSource(),
  );

  // Mapper
  serviceLocator.registerLazySingleton<CompanyMapper>(
    () => const CompanyMapper(),
  );

  // Repository
  serviceLocator.registerLazySingleton<CompanyRepository>(
    () => CompanyRepositoryImpl(
      remoteDataSource: serviceLocator<CompanyRemoteDataSource>(),
      localDataSource: serviceLocator<CompanyLocalDataSource>(),
      mapper: serviceLocator<CompanyMapper>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetCompaniesUseCase>(
    () => GetCompaniesUseCase(serviceLocator<CompanyRepository>()),
  );
  serviceLocator.registerLazySingleton<GetCompanyByIdUseCase>(
    () => GetCompanyByIdUseCase(serviceLocator<CompanyRepository>()),
  );
  serviceLocator.registerLazySingleton<SearchCompaniesUseCase>(
    () => SearchCompaniesUseCase(serviceLocator<CompanyRepository>()),
  );
  serviceLocator.registerLazySingleton<FilterCompaniesUseCase>(
    () => FilterCompaniesUseCase(serviceLocator<CompanyRepository>()),
  );
  serviceLocator.registerLazySingleton<SearchAndFilterCompaniesUseCase>(
    () => SearchAndFilterCompaniesUseCase(serviceLocator<CompanyRepository>()),
  );

  // Commands
  serviceLocator.registerLazySingleton<GetCompaniesCommand>(
    () => GetCompaniesCommand(serviceLocator<GetCompaniesUseCase>()),
  );
  serviceLocator.registerLazySingleton<GetCompanyByIdCommand>(
    () => GetCompanyByIdCommand(serviceLocator<GetCompanyByIdUseCase>()),
  );
  serviceLocator.registerLazySingleton<SearchCompaniesCommand>(
    () => SearchCompaniesCommand(serviceLocator<SearchCompaniesUseCase>()),
  );
  serviceLocator.registerLazySingleton<FilterCompaniesCommand>(
    () => FilterCompaniesCommand(serviceLocator<FilterCompaniesUseCase>()),
  );
  serviceLocator.registerLazySingleton<SearchAndFilterCompaniesCommand>(
    () => SearchAndFilterCompaniesCommand(
      serviceLocator<SearchAndFilterCompaniesUseCase>(),
    ),
  );

  // View models
  serviceLocator.registerLazySingleton<CompanyViewModel>(
    () => CompanyViewModel(
      getCompaniesCommand: serviceLocator<GetCompaniesCommand>(),
      searchCompaniesCommand: serviceLocator<SearchCompaniesCommand>(),
      filterCompaniesCommand: serviceLocator<FilterCompaniesCommand>(),
      searchAndFilterCommand: serviceLocator<SearchAndFilterCompaniesCommand>(),
    ),
  );
  serviceLocator.registerLazySingleton<CompanyDetailViewModel>(
    () => CompanyDetailViewModel(
      getCompanyByIdCommand: serviceLocator<GetCompanyByIdCommand>(),
    ),
  );
}

/// Setup Student Session feature with clean architecture
void _setupStudentSessionFeature() {
  // Data sources
  serviceLocator.registerLazySingleton<StudentSessionRemoteDataSource>(
    () => StudentSessionRemoteDataSource(serviceLocator<ArkadApi>()),
  );
  serviceLocator.registerLazySingleton<StudentSessionLocalDataSource>(
    () => StudentSessionLocalDataSource(),
  );

  // Mapper
  serviceLocator.registerLazySingleton<StudentSessionMapper>(
    () => const StudentSessionMapper(),
  );

  // Repository
  serviceLocator.registerLazySingleton<StudentSessionRepository>(
    () => StudentSessionRepositoryImpl(
      remoteDataSource: serviceLocator<StudentSessionRemoteDataSource>(),
      localDataSource: serviceLocator<StudentSessionLocalDataSource>(),
      mapper: serviceLocator<StudentSessionMapper>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetStudentSessionsUseCase>(
    () => GetStudentSessionsUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<ApplyForSessionUseCase>(
    () => ApplyForSessionUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<CancelApplicationUseCase>(
    () => CancelApplicationUseCase(serviceLocator<StudentSessionRepository>()),
  );

  // View model
  serviceLocator.registerLazySingleton<StudentSessionViewModel>(
    () => StudentSessionViewModel(
      getStudentSessionsUseCase: serviceLocator<GetStudentSessionsUseCase>(),
      applyForSessionUseCase: serviceLocator<ApplyForSessionUseCase>(),
      cancelApplicationUseCase: serviceLocator<CancelApplicationUseCase>(),
    ),
  );
}

/// Setup Event feature with clean architecture
void _setupEventFeature() {
  // Data sources
  serviceLocator.registerLazySingleton<EventRemoteDataSource>(
    () => EventRemoteDataSource(serviceLocator<ArkadApi>()),
  );

  // Mappers
  serviceLocator.registerLazySingleton<EventMapper>(() => EventMapper());
  serviceLocator.registerLazySingleton<EventAttendeeMapper>(
    () => EventAttendeeMapper(),
  );
  serviceLocator.registerLazySingleton<TicketVerificationMapper>(
    () => TicketVerificationMapper(),
  );

  // Repository
  serviceLocator.registerLazySingleton<EventRepository>(
    () => EventRepositoryImpl(
      remoteDataSource: serviceLocator<EventRemoteDataSource>(),
      mapper: serviceLocator<EventMapper>(),
      attendeeMapper: serviceLocator<EventAttendeeMapper>(),
      ticketMapper: serviceLocator<TicketVerificationMapper>(),
    ),
  );

  // View model
  serviceLocator.registerLazySingleton<EventViewModel>(
    () => EventViewModel(eventRepository: serviceLocator<EventRepository>()),
  );
}

/// Setup Map feature with minimal clean architecture
void _setupMapFeature() {
  // Repository (placeholder implementation)
  serviceLocator.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(),
  );

  // View model
  serviceLocator.registerLazySingleton<MapViewModel>(
    () => MapViewModel(mapRepository: serviceLocator<MapRepository>()),
  );
}
