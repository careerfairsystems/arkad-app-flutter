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
      if (_messaging == null) return null;
      if (kIsWeb) return null;

      _currentToken ??= await _messaging!.getToken();
      return _currentToken;
    } catch (e, stackTrace) {
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
}
