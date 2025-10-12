import 'package:app_settings/app_settings.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for managing Firebase Cloud Messaging
class FcmService {
  FcmService._();

  static final FcmService _instance = FcmService._();
  static FcmService get instance => _instance;

  FirebaseMessaging? _messaging;
  String? _currentToken;

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
