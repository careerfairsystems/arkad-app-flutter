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
import '../features/auth/domain/use_cases/refresh_session_use_case.dart';
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
import '../features/notifications/data/data_sources/notification_local_data_source.dart';
import '../features/notifications/data/data_sources/notification_remote_data_source.dart';
import '../features/notifications/data/repositories/notification_repository_impl.dart';
import '../features/notifications/domain/repositories/notification_repository.dart';
import '../features/notifications/domain/use_cases/sync_fcm_token_use_case.dart';
import '../features/notifications/presentation/view_models/notification_view_model.dart';
import '../features/profile/data/data_sources/profile_local_data_source.dart';
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/use_cases/delete_cv_use_case.dart';
import '../features/profile/domain/use_cases/delete_profile_picture_use_case.dart';
import '../features/profile/domain/use_cases/get_current_profile_use_case.dart';
import '../features/profile/domain/use_cases/update_profile_use_case.dart';
import '../features/profile/domain/use_cases/upload_cv_use_case.dart'
    as profile_cv;
import '../features/profile/domain/use_cases/upload_profile_picture_use_case.dart';
import '../features/profile/presentation/view_models/profile_view_model.dart';
import '../features/student_session/data/data_sources/student_session_remote_data_source.dart';
import '../features/student_session/data/mappers/student_session_mapper.dart';
import '../features/student_session/data/repositories/student_session_repository_impl.dart';
import '../features/student_session/domain/repositories/student_session_repository.dart';
import '../features/student_session/domain/services/student_session_data_service.dart';
import '../features/student_session/domain/use_cases/apply_for_session_use_case.dart';
import '../features/student_session/domain/use_cases/book_timeslot_use_case.dart';
import '../features/student_session/domain/use_cases/get_my_applications_with_booking_state_use_case.dart';
import '../features/student_session/domain/use_cases/get_student_sessions_use_case.dart';
import '../features/student_session/domain/use_cases/get_timeslots_use_case.dart';
import '../features/student_session/domain/use_cases/switch_timeslot_use_case.dart';
import '../features/student_session/domain/use_cases/unbook_timeslot_use_case.dart';
import '../features/student_session/domain/use_cases/upload_cv_use_case.dart';
import '../features/student_session/presentation/commands/apply_for_session_command.dart';
import '../features/student_session/presentation/commands/book_timeslot_command.dart';
import '../features/student_session/presentation/commands/get_my_applications_with_booking_state_command.dart';
import '../features/student_session/presentation/commands/get_student_sessions_command.dart';
import '../features/student_session/presentation/commands/get_timeslots_command.dart';
import '../features/student_session/presentation/commands/switch_timeslot_command.dart';
import '../features/student_session/presentation/commands/unbook_timeslot_command.dart';
import '../features/student_session/presentation/view_models/student_session_view_model.dart';
import '../shared/infrastructure/app_environment.dart';
import '../shared/infrastructure/services/file_service.dart';

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
}

/// Setup API client conditionally
void _setupApiClient() {
  // Try to register API client - will work after generation
  _registerApiClientConditionally();
}

/// Register API client
void _registerApiClientConditionally() {
  serviceLocator.registerLazySingleton<ArkadApi>(() {
    // Create custom Dio instance with reasonable timeout configuration
    final dio = Dio(
      BaseOptions(
        baseUrl: AppEnvironment.baseUrl,
        connectTimeout: const Duration(seconds: 10), // Connection establishment
        receiveTimeout: const Duration(seconds: 15), // Receiving response data
        sendTimeout: const Duration(seconds: 10), // Sending request data
      ),
    );

    // Pass custom Dio to ArkadApi (interceptors will be added by ArkadApi)
    return ArkadApi(dio: dio, basePathOverride: AppEnvironment.baseUrl);
  });

  // Register the Dio instance from ArkadApi for other services that need it
  serviceLocator.registerLazySingleton<Dio>(
    () => serviceLocator<ArkadApi>().dio,
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
  serviceLocator.registerLazySingleton<RefreshSessionUseCase>(
    () => RefreshSessionUseCase(serviceLocator<AuthRepository>()),
  );
  final authViewModel = AuthViewModel(
    signInUseCase: serviceLocator<SignInUseCase>(),
    signUpUseCase: serviceLocator<SignUpUseCase>(),
    completeSignupUseCase: serviceLocator<CompleteSignupUseCase>(),
    resetPasswordUseCase: serviceLocator<ResetPasswordUseCase>(),
    resendVerificationUseCase: serviceLocator<ResendVerificationUseCase>(),
    signOutUseCase: serviceLocator<SignOutUseCase>(),
    getCurrentSessionUseCase: serviceLocator<GetCurrentSessionUseCase>(),
    refreshSessionUseCase: serviceLocator<RefreshSessionUseCase>(),
  );

  // View model
  serviceLocator.registerSingleton<AuthViewModel>(authViewModel);
  _setupNotificationFeature(authViewModel);
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
  serviceLocator.registerLazySingleton<profile_cv.UploadCVUseCase>(
    () => profile_cv.UploadCVUseCase(serviceLocator<ProfileRepository>()),
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
      uploadCVUseCase: serviceLocator<profile_cv.UploadCVUseCase>(),
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

  // Mapper
  serviceLocator.registerLazySingleton<StudentSessionMapper>(
    () => const StudentSessionMapper(),
  );

  // Repository
  serviceLocator.registerLazySingleton<StudentSessionRepository>(
    () => StudentSessionRepositoryImpl(
      remoteDataSource: serviceLocator<StudentSessionRemoteDataSource>(),
      mapper: serviceLocator<StudentSessionMapper>(),
      getCompanyByIdUseCase: serviceLocator<GetCompanyByIdUseCase>(),
    ),
  );

  // Use cases
  serviceLocator.registerLazySingleton<GetStudentSessionsUseCase>(
    () => GetStudentSessionsUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<ApplyForSessionUseCase>(
    () => ApplyForSessionUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<BookTimeslotUseCase>(
    () => BookTimeslotUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<UnbookTimeslotUseCase>(
    () => UnbookTimeslotUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<SwitchTimeslotUseCase>(
    () => SwitchTimeslotUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator
      .registerLazySingleton<GetMyApplicationsWithBookingStateUseCase>(
        () => GetMyApplicationsWithBookingStateUseCase(
          serviceLocator<StudentSessionRepository>(),
        ),
      );
  serviceLocator.registerLazySingleton<GetTimeslotsUseCase>(
    () => GetTimeslotsUseCase(serviceLocator<StudentSessionRepository>()),
  );
  serviceLocator.registerLazySingleton<UploadCVUseCase>(
    () => UploadCVUseCase(serviceLocator<StudentSessionRepository>()),
  );

  // Services
  serviceLocator.registerLazySingleton<StudentSessionDataService>(
    () => StudentSessionDataService(
      repository: serviceLocator<StudentSessionRepository>(),
    ),
  );

  // Commands
  serviceLocator.registerLazySingleton<GetStudentSessionsCommand>(
    () =>
        GetStudentSessionsCommand(serviceLocator<GetStudentSessionsUseCase>()),
  );
  serviceLocator.registerLazySingleton<ApplyForSessionCommand>(
    () => ApplyForSessionCommand(serviceLocator<ApplyForSessionUseCase>()),
  );
  serviceLocator.registerLazySingleton<BookTimeslotCommand>(
    () => BookTimeslotCommand(serviceLocator<BookTimeslotUseCase>()),
  );
  serviceLocator.registerLazySingleton<UnbookTimeslotCommand>(
    () => UnbookTimeslotCommand(serviceLocator<UnbookTimeslotUseCase>()),
  );
  serviceLocator.registerLazySingleton<SwitchTimeslotCommand>(
    () => SwitchTimeslotCommand(serviceLocator<SwitchTimeslotUseCase>()),
  );
  serviceLocator
      .registerLazySingleton<GetMyApplicationsWithBookingStateCommand>(
        () => GetMyApplicationsWithBookingStateCommand(
          serviceLocator<GetMyApplicationsWithBookingStateUseCase>(),
        ),
      );
  serviceLocator.registerLazySingleton<GetTimeslotsCommand>(
    () => GetTimeslotsCommand(serviceLocator<GetTimeslotsUseCase>()),
  );

  // View model
  serviceLocator.registerLazySingleton<StudentSessionViewModel>(
    () => StudentSessionViewModel(
      getStudentSessionsCommand: serviceLocator<GetStudentSessionsCommand>(),
      applyForSessionCommand: serviceLocator<ApplyForSessionCommand>(),
      bookTimeslotCommand: serviceLocator<BookTimeslotCommand>(),
      unbookTimeslotCommand: serviceLocator<UnbookTimeslotCommand>(),
      switchTimeslotCommand: serviceLocator<SwitchTimeslotCommand>(),
      getMyApplicationsWithBookingStateCommand:
          serviceLocator<GetMyApplicationsWithBookingStateCommand>(),
      getTimeslotsCommand: serviceLocator<GetTimeslotsCommand>(),
      uploadCVUseCase: serviceLocator<UploadCVUseCase>(),
      authViewModel: serviceLocator<AuthViewModel>(),
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

/// Setup Notification feature with clean architecture
void _setupNotificationFeature(AuthViewModel authViewModel) {
  // Data sources
  serviceLocator.registerLazySingleton<NotificationLocalDataSource>(
    () =>
        NotificationLocalDataSourceImpl(serviceLocator<FlutterSecureStorage>()),
  );
  serviceLocator.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(serviceLocator<ArkadApi>()),
  );

  // Repository
  serviceLocator.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(
      serviceLocator<NotificationRemoteDataSource>(),
      serviceLocator<NotificationLocalDataSource>(),
    ),
  );
  final useCase = SyncFcmTokenUseCase(serviceLocator<NotificationRepository>());

  // Use cases
  serviceLocator.registerSingleton<SyncFcmTokenUseCase>(useCase);
  final viewModel = NotificationViewModel(
    syncFcmTokenUseCase: useCase,
    authViewModel: authViewModel,
  );

  // View model
  serviceLocator.registerSingleton<NotificationViewModel>(viewModel);
}
