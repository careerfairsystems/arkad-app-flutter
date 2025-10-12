import 'dart:async';

import 'package:arkad/navigation/navigation_items.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_combainsdk/combain_logger.dart';
import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
import '../features/map/data/repositories/location_repository_impl.dart';
import '../features/map/data/repositories/map_repository_impl.dart';
import '../features/map/data/services/permission_service.dart';
import '../features/map/domain/repositories/location_repository.dart';
import '../features/map/domain/repositories/map_repository.dart';
import '../features/map/presentation/providers/location_provider.dart';
import '../features/map/presentation/view_models/map_permissions_view_model.dart';
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

/// Centrialized initialization of all the services and providers. An alternative to Flutter's inherited widgets and provides a more decoupled way to access services and providers throughout the app. This abstracts the complexity from lower-level components and avoids the need to pass dependencies down the widget tree.

class ArkadCombainLogger implements CombainLogger {
  @override
  void d(String tag, String message) {
    Sentry.logger.debug(
      message,
      attributes: {
        'origin': SentryLogAttribute.string('combain_sdk'),
        'tag': SentryLogAttribute.string(tag),
      },
    );
  }

  @override
  void e(String tag, String message) {
    Sentry.logger.error(
      message,
      attributes: {
        'origin': SentryLogAttribute.string('combain_sdk'),
        'tag': SentryLogAttribute.string(tag),
      },
    );
  }

  @override
  void i(String tag, String message) {
    Sentry.logger.info(
      message,
      attributes: {
        'origin': SentryLogAttribute.string('combain_sdk'),
        'tag': SentryLogAttribute.string(tag),
      },
    );
  }

  @override
  void w(String tag, String message) {
    Sentry.logger.warn(
      message,
      attributes: {
        'origin': SentryLogAttribute.string('combain_sdk'),
        'tag': SentryLogAttribute.string(tag),
      },
    );
  }
}

class CombainIntializer extends ChangeNotifier {
  final PackageInfo _packageInfo;

  CombainIntializer(this._packageInfo);

  var combainIntialized = false;
  FlutterCombainSDK? _combainSDK;

  /// Mark as initialized (used for web platform)
  void markAsInitialized() {
    combainIntialized = true;
    notifyListeners();
  }

  /// Initialize SDK without starting it (config setup only)
  Future<void> initializeWithoutStart() async {
    if (!shouldShowMap()) {
      return;
    }
    if (_combainSDK != null) {
      print("Combain SDK already initialized");
      return;
    }

    print("Running combain SDK configuration");

    // Combain SDK initialization with persistent device UUID
    final deviceId = await _getOrCreateDeviceId();
    final combainConfig = CombainSDKConfig(
      apiKey: "848bb5dadbcba210e0ad",
      settingsKey: "848bb5dadbcba210e0ad",
      locationProvider: FlutterLocationProvider.aiNavigation,
      routingConfig: FlutterRoutingConfig(
        routableNodesOptions: FlutterRoutableNodesOptions.allExceptDefaultName,
      ),
      deviceIdentifier: deviceId,
      appInfo: FlutterAppInfo(
        packageName: _packageInfo.packageName,
        versionName: _packageInfo.version,
        versionCode: int.tryParse(_packageInfo.buildNumber) ?? 0,
      ),
      syncingInterval: FlutterSyncingInterval(
        type: FlutterSyncingIntervalType.interval,
        intervalMilliseconds: 60 * 1000 * 60,
      ),
      wifiEnabled: true,
      bluetoothEnabled: true,
      beaconUUIDs: ["E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"],
    );

    // Step 1: Create the SDK instance
    _combainSDK = await FlutterCombainSDK.create();
    print("Created SDK instance");

    // Step 2: Initialize the SDK with the config
    await _combainSDK!.initializeSDK(combainConfig);
    print("Initialized SDK config");

    // Register SDK instance so it can be used by PermissionsDataSource
    serviceLocator.registerSingleton(_combainSDK!);
  }

  /// Start the SDK after permissions are granted
  Future<void> startSDK() async {
    if (!shouldShowMap()) {
      return;
    }
    if (_combainSDK == null) {
      print("Cannot start SDK - not initialized");
      return;
    }

    if (combainIntialized) {
      print("Combain SDK already started");
      return;
    }

    print("Starting Combain SDK");
    await _combainSDK!.start();
    combainIntialized = true;
    notifyListeners();
  }
}

// We could have used InheritedWidget or riverpod package to handle state, but GetIt with provider is a solid combo to my understanding.
Future<void> setupServiceLocator() async {
  // Core services - PackageInfo must be first as other services depend on it
  final packageInfo = await PackageInfo.fromPlatform();
  serviceLocator.registerSingleton<PackageInfo>(packageInfo);

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

  // Register Combain initializer with injected PackageInfo
  serviceLocator.registerSingleton<CombainIntializer>(
    CombainIntializer(serviceLocator<PackageInfo>()),
  );

  // Clean architecture features
  _setupAuthFeature();
  _setupProfileFeature();
  _setupCompanyFeature();
  _setupStudentSessionFeature();
  _setupEventFeature();
  await _setupMapFeature();
}

/// Get or create a persistent device UUID for Combain SDK
Future<String> _getOrCreateDeviceId() async {
  const String deviceIdKey = 'combain_device_id';
  final prefs = await SharedPreferences.getInstance();

  String? deviceId = prefs.getString(deviceIdKey);

  if (deviceId == null || deviceId.isEmpty) {
    // Generate new UUID
    deviceId = const Uuid().v4();
    await prefs.setString(deviceIdKey, deviceId);
  }

  return deviceId;
}

/// Setup API client conditionally
void _setupApiClient() {
  // Try to register API client - will work after generation
  _registerApiClientConditionally();
}

/// Register API client
void _registerApiClientConditionally() {
  serviceLocator.registerLazySingleton<ArkadApi>(
    () => ArkadApi(
      // Let ArkadApi create its own Dio with interceptors
      basePathOverride: AppEnvironment.baseUrl,
    ),
  );

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

/// Setup Map feature with permission-gated SDK initialization
Future<void> _setupMapFeature() async {
  // Initialize Combain SDK config WITHOUT starting it
  final combainInitializer = serviceLocator<CombainIntializer>();
  await combainInitializer.initializeWithoutStart();

  // Setup permission service for map
  serviceLocator.registerLazySingleton<PermissionService>(
    () => PermissionService(),
  );

  serviceLocator.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(),
  );

  // Repository (placeholder implementation)
  serviceLocator.registerLazySingleton<MapRepository>(
    () => MapRepositoryImpl(),
  );

  serviceLocator.registerLazySingleton<LocationProvider>(
    () => LocationProvider(
      serviceLocator<LocationRepository>(),
      serviceLocator<MapRepository>(),
    ),
  );

  // View models
  serviceLocator.registerLazySingleton<MapViewModel>(
    () => MapViewModel(mapRepository: serviceLocator<MapRepository>()),
  );

  serviceLocator.registerLazySingleton<MapPermissionsViewModel>(
    () => MapPermissionsViewModel(
      permissionService: serviceLocator<PermissionService>(),
      combainInitializer: combainInitializer,
    ),
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
