import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../navigation/app_router.dart';

/// Top-level function for background message handling
/// MUST be top-level or static to work with FCM background handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Sentry.addBreadcrumb(
    Breadcrumb(
      message:
          'Background FCM message received: ${message.notification?.title}',
      level: SentryLevel.info,
    ),
  );
}

/// Service for managing Firebase Cloud Messaging
class FcmService {
  final _appRouter = GetIt.I<AppRouter>();

  FirebaseMessaging? _messaging;
  String? _currentToken;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Initialize Firebase and FCM
  Future<void> initialize() async {
    try {
      // Skip initialization for web platform
      if (kIsWeb) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'FCM not initialized - web platform not supported',
            level: SentryLevel.info,
          ),
        );
        return;
      }

      // Initialize Firebase
      await Firebase.initializeApp();

      // Get FCM instance
      _messaging = FirebaseMessaging.instance;

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Request permissions
      await requestPermission();

      // Get initial token
      _currentToken = await _messaging?.getToken();

      // Listen to token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          _currentToken = newToken;
          Sentry.addBreadcrumb(
            Breadcrumb(message: 'FCM token refreshed', level: SentryLevel.info),
          );
        },
        onError: (error, stackTrace) {
          Sentry.captureException(error, stackTrace: stackTrace);
        },
      );

      // Set up foreground message handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

      // App opened from a terminated state by tapping a notification
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) {
        _handleMessage(initial, deferToFirstFrame: true);
      }

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'FCM initialized successfully',
          level: SentryLevel.info,
        ),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  void _handleMessage(RemoteMessage message, {bool deferToFirstFrame = false}) {
    final link = message.data['link'] ?? message.data['url'];
    if (link is! String || link.isEmpty) return;

    final uri = Uri.parse(link);

    void nav() => _routeToUri(uri);

    if (deferToFirstFrame) {
      WidgetsBinding.instance.addPostFrameCallback((_) => nav());
    } else {
      nav();
    }
  }

  Future<void> _routeToUri(Uri uri) async {
    // Handle universal links on your domain by mirroring the path+query into go_router.
    if (uri.scheme == 'https' && uri.host == 'app.arkadtlth.se') {
      // Normalize the path (ensure leading slash, collapse //).
      var path = uri.path.isEmpty
          ? '/'
          : uri.path.replaceAll(RegExp(r'/{2,}'), '/');

      // Preserve query and fragment (if you use fragments).
      final query = uri.hasQuery ? '?${uri.query}' : '';
      final fragment = uri.hasFragment ? '#${uri.fragment}' : '';

      _appRouter.router.go('$path$query$fragment'); // e.g., /schedule?day=2
      return;
    }

    // Everything else opens externally (or add more in-app rules above).
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _onForegroundNotificationClick(NotificationResponse res) {
    final payload = res.payload;

    if (payload == null || payload.isEmpty) return;

    try {
      final data = Uri.parse(payload);
      _routeToUri(data);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Combined initialization settings
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onForegroundNotificationClick,
      );

      // Create Android notification channel
      const androidChannel = AndroidNotificationChannel(
        'arkad_notifications',
        'Arkad Notifications',
        description: 'Important notifications from Arkad',
        importance: Importance.high,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Local notifications initialized',
          level: SentryLevel.info,
        ),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    try {
      Sentry.logger.info(
        'Foreground FCM message received',
        attributes: {
          'title': SentryLogAttribute.string(
            message.notification?.title ?? 'No title',
          ),
          'body': SentryLogAttribute.string(
            message.notification?.body ?? 'No body',
          ),
        },
      );

      // Display notification using local notifications
      if (message.notification != null) {
        await _showNotification(message);
      }
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Display notification using flutter_local_notifications
  Future<void> _showNotification(RemoteMessage message) async {
    try {
      final notification = message.notification;
      if (notification == null) return;

      const androidDetails = AndroidNotificationDetails(
        'arkad_notifications',
        'Arkad Notifications',
        channelDescription: 'Important notifications from Arkad',
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
        payload: message.data.toString(),
      );

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Notification displayed: ${notification.title}',
          level: SentryLevel.info,
        ),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Request notification permissions
  /// Returns true if permission was granted
  Future<bool> requestPermission() async {
    try {
      if (_messaging == null) return false;

      // Skip permission request for web
      if (kIsWeb) return false;

      final settings = await _messaging!.requestPermission();

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message:
              'FCM permission request result: ${settings.authorizationStatus.name}',
          level: SentryLevel.info,
        ),
      );

      return granted;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get current FCM token
  Future<String?> getToken() async {
    try {
      if (_messaging == null) {
        Sentry.logger.info('FCM Service: Messaging instance is null');
        return null;
      }
      if (kIsWeb) {
        Sentry.logger.info('FCM Service: Web platform - token not available');
        return null;
      }

      _currentToken ??= await _messaging!.getToken();

      if (_currentToken != null) {
        Sentry.logger.info(
          'FCM Service: Token retrieved successfully',
          attributes: {
            'token_length': SentryLogAttribute.int(_currentToken!.length),
            'was_cached': SentryLogAttribute.bool(_currentToken != null),
          },
        );
      } else {
        Sentry.logger.info('FCM Service: Token is null after retrieval');
      }

      return _currentToken;
    } catch (e, stackTrace) {
      Sentry.logger.fmt.error(
        'FCM Service: Exception while getting token: %s',
        [e.toString()],
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    try {
      if (_messaging == null) return false;
      if (kIsWeb) return false;

      final settings = await _messaging!.getNotificationSettings();
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Open app settings page
  Future<void> openAppSettings() async {
    try {
      if (kIsWeb) {
        await Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Cannot open settings - web platform not supported',
            level: SentryLevel.info,
          ),
        );
        return;
      }

      await AppSettings.openAppSettings(type: AppSettingsType.notification);
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Opened app notification settings',
          level: SentryLevel.info,
        ),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
    }
  }

  /// Subscribe to a topic
  Future<bool> subscribeToTopic(String topic) async {
    try {
      if (_messaging == null) {
        Sentry.logger.info(
          'FCM Service: Cannot subscribe - messaging instance is null',
        );
        return false;
      }
      if (kIsWeb) {
        Sentry.logger.info(
          'FCM Service: Web platform - topic subscription not available',
        );
        return false;
      }

      await _messaging!.subscribeToTopic(topic);

      Sentry.logger.info(
        'FCM Service: Successfully subscribed to topic',
        attributes: {'topic': SentryLogAttribute.string(topic)},
      );

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Subscribed to FCM topic: $topic',
          level: SentryLevel.info,
        ),
      );

      return true;
    } catch (e, stackTrace) {
      Sentry.logger.fmt.error(
        'FCM Service: Exception while subscribing to topic %s: %s',
        [topic, e.toString()],
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Unsubscribe from a topic
  Future<bool> unsubscribeFromTopic(String topic) async {
    try {
      if (_messaging == null) {
        Sentry.logger.info(
          'FCM Service: Cannot unsubscribe - messaging instance is null',
        );
        return false;
      }
      if (kIsWeb) {
        Sentry.logger.info(
          'FCM Service: Web platform - topic unsubscription not available',
        );
        return false;
      }

      await _messaging!.unsubscribeFromTopic(topic);

      Sentry.logger.info(
        'FCM Service: Successfully unsubscribed from topic',
        attributes: {'topic': SentryLogAttribute.string(topic)},
      );

      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Unsubscribed from FCM topic: $topic',
          level: SentryLevel.info,
        ),
      );

      return true;
    } catch (e, stackTrace) {
      Sentry.logger.fmt.error(
        'FCM Service: Exception while unsubscribing from topic %s: %s',
        [topic, e.toString()],
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }
}
