import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../data/services/fcm_service.dart';
import '../../domain/use_cases/sync_fcm_token_use_case.dart';
import '../commands/sync_fcm_token_command.dart';

/// View model for managing push notifications
class NotificationViewModel extends ChangeNotifier with WidgetsBindingObserver {
  NotificationViewModel({
    required SyncFcmTokenUseCase syncFcmTokenUseCase,
    required AuthViewModel authViewModel,
  }) : _authViewModel = authViewModel {
    // Initialize command
    _syncFcmTokenCommand = SyncFcmTokenCommand(syncFcmTokenUseCase);

    // Listen to command changes
    _syncFcmTokenCommand.addListener(_onSyncCommandChanged);

    // Subscribe to auth events
    _subscribeToAuthEvents();

    // Add lifecycle observer to refresh permissions when app resumes
    WidgetsBinding.instance.addObserver(this);

    initializeFcm();
  }

  final AuthViewModel _authViewModel;
  final FcmService _fcmService = FcmService.instance;

  late final SyncFcmTokenCommand _syncFcmTokenCommand;
  StreamSubscription<AuthSessionChangedEvent>? _authSessionChangedSubscription;
  StreamSubscription<UserLoggedOutEvent>? _logoutSubscription;

  bool _isInitialized = false;
  bool _permissionGranted = false;

  // Getters
  SyncFcmTokenCommand get syncFcmTokenCommand => _syncFcmTokenCommand;
  bool get isInitialized => _isInitialized;
  bool get permissionGranted => _permissionGranted;
  bool get isSyncing => _syncFcmTokenCommand.isExecuting;

  /// Initialize FCM service
  Future<void> initializeFcm() async {
    try {
      await _fcmService.initialize();
      _permissionGranted = await _fcmService.areNotificationsEnabled();
      _isInitialized = true;
      notifyListeners();

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM initialized - permission: $_permissionGranted',
          level: SentryLevel.info,
        ),
      );

      // Subscribe to broadcast topic
      await _subscribeToBroadcast();

      // Sync token on app start if authenticated (after FCM is ready)
      await _syncTokenOnStartup();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      _isInitialized = false;
      notifyListeners();
    }
  }

  /// Sync token on app startup if user is authenticated
  Future<void> _syncTokenOnStartup() async {
    try {
      // Wait for auth initialization to complete
      await _authViewModel.waitForInitialization;

      // Check if user is authenticated
      if (!_authViewModel.isAuthenticated) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'App started - user not authenticated, skipping FCM sync',
            level: SentryLevel.info,
          ),
        );
        return;
      }

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'App started - user authenticated, syncing FCM token',
          level: SentryLevel.info,
        ),
      );

      // Check if permissions are granted, if not request them
      if (!_permissionGranted) {
        await requestPermissionAndSync();
      } else {
        await syncFcmToken();
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Request notification permission and sync token if granted
  Future<void> requestPermissionAndSync() async {
    try {
      final granted = await _fcmService.requestPermission();
      _permissionGranted = granted;
      notifyListeners();

      if (granted) {
        await syncFcmToken();
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Sync FCM token with backend
  Future<void> syncFcmToken() async {
    try {
      if (!_isInitialized) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Cannot sync FCM token - not initialized',
            level: SentryLevel.warning,
          ),
        );
        return;
      }

      final token = await _fcmService.getToken();
      if (token == null || token.isEmpty) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Cannot sync FCM token - no token available',
            level: SentryLevel.warning,
          ),
        );
        return;
      }

      await _syncFcmTokenCommand.syncToken(token);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Subscribe to broadcast topic
  Future<void> _subscribeToBroadcast() async {
    try {
      if (!_isInitialized) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Cannot subscribe to broadcast - FCM not initialized',
            level: SentryLevel.warning,
          ),
        );
        return;
      }

      var success = false;
      if (kDebugMode) {
        success = await _fcmService.subscribeToTopic('debug_broadcast');
      } else {
        success = await _fcmService.subscribeToTopic('broadcast');
      }

      if (success) {
        Sentry.logger.info('Successfully subscribed to broadcast topic');
      } else {
        Sentry.logger.info(
          'Failed to subscribe to broadcast topic',
          attributes: {'success': SentryLogAttribute.bool(false)},
        );
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Unsubscribe from broadcast topic
  /// DO we ever want to do this?
  Future<void> _unsubscribeFromBroadcast() async {
    try {
      if (!_isInitialized) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Cannot unsubscribe from broadcast - FCM not initialized',
            level: SentryLevel.warning,
          ),
        );
        return;
      }

      var success = false;
      if (kDebugMode) {
        success = await _fcmService.unsubscribeFromTopic('debug_broadcast');
      } else {
        success = await _fcmService.unsubscribeFromTopic('broadcast');
      }

      if (success) {
        Sentry.logger.info('Successfully unsubscribed from broadcast topic');
      } else {
        Sentry.logger.info(
          'Failed to unsubscribe from broadcast topic',
          attributes: {'success': SentryLogAttribute.bool(false)},
        );
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Subscribe to authentication events
  void _subscribeToAuthEvents() {
    // Listen to sign in/sign up events
    _authSessionChangedSubscription = AppEvents.on<AuthSessionChangedEvent>()
        .listen((event) async {
          Sentry.logger.info(
            'ViewModel: User authenticated event received - initiating FCM token sync',
            attributes: {
              'permissions_granted': SentryLogAttribute.bool(
                _permissionGranted,
              ),
            },
          );

          await Sentry.addBreadcrumb(
            Breadcrumb(
              message: 'User authenticated - syncing FCM token',
              level: SentryLevel.info,
            ),
          );

          // Subscribe to broadcast topic on sign in
          await _subscribeToBroadcast();

          // Check if permissions are granted, if not request them
          if (!_permissionGranted) {
            Sentry.logger.info(
              'ViewModel: FCM permissions not granted - requesting permission',
            );
            await requestPermissionAndSync();
          } else {
            Sentry.logger.info(
              'ViewModel: FCM permissions already granted - syncing token',
            );
            await syncFcmToken();
          }
        });

    // Listen to logout events
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) async {
      Sentry.logger.info(
        'ViewModel: User logged out event received - clearing FCM token from backend',
      );

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'User logged out - clearing FCM token on backend',
          level: SentryLevel.info,
        ),
      );

      // Send empty string to backend to clear FCM token registration
      await _syncFcmTokenCommand.syncToken('');

      notifyListeners();
    });
  }

  /// Handle sync command state changes
  void _onSyncCommandChanged() {
    if (_syncFcmTokenCommand.isCompleted && !_syncFcmTokenCommand.hasError) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM token synced successfully',
          level: SentryLevel.info,
        ),
      );
    } else if (_syncFcmTokenCommand.hasError) {
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM token sync failed: ${_syncFcmTokenCommand.error}',
          level: SentryLevel.warning,
        ),
      );
    }
    notifyListeners();
  }

  /// Handle app lifecycle changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissionStatus();
    }
  }

  /// Refresh notification permission status
  Future<void> _refreshPermissionStatus() async {
    try {
      if (!_isInitialized) return;

      final granted = await _fcmService.areNotificationsEnabled();
      if (_permissionGranted != granted) {
        _permissionGranted = granted;
        notifyListeners();

        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Notification permission status refreshed: $granted',
            level: SentryLevel.info,
          ),
        );
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authSessionChangedSubscription?.cancel();
    _logoutSubscription?.cancel();
    _syncFcmTokenCommand.removeListener(_onSyncCommandChanged);
    super.dispose();
  }
}
