import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../domain/entities/fcm_token_info.dart';

/// Abstract interface for notification local data source
abstract class NotificationLocalDataSource {
  Future<FcmTokenInfo?> getTokenInfo();
  Future<void> saveTokenInfo(FcmTokenInfo tokenInfo);
  Future<void> clearTokenInfo();
}

/// Implementation of notification local data source using secure storage
class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  const NotificationLocalDataSourceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const String _tokenKey = 'fcm_token';
  static const String _lastSentAtKey = 'fcm_token_last_sent_at';

  @override
  Future<FcmTokenInfo?> getTokenInfo() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final lastSentAtStr = await _secureStorage.read(key: _lastSentAtKey);

      if (token == null || lastSentAtStr == null) {
        return null;
      }

      final lastSentAt = DateTime.parse(lastSentAtStr);

      return FcmTokenInfo(token: token, lastSentAt: lastSentAt);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      // If there's any error reading token info, return null
      return null;
    }
  }

  @override
  Future<void> saveTokenInfo(FcmTokenInfo tokenInfo) async {
    try {
      await Future.wait([
        _secureStorage.write(key: _tokenKey, value: tokenInfo.token),
        _secureStorage.write(
          key: _lastSentAtKey,
          value: tokenInfo.lastSentAt.toIso8601String(),
        ),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Failed to save FCM token info: $e');
    }
  }

  @override
  Future<void> clearTokenInfo() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _lastSentAtKey),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      // Ignore errors when clearing
    }
  }
}
