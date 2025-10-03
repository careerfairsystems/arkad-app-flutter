import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/errors/exception.dart';

/// Abstract interface for notification remote data source
abstract class NotificationRemoteDataSource {
  Future<void> sendFcmToken(String token);
}

/// Implementation of notification remote data source using auto-generated API client
class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._api);

  final ArkadApi _api;

  @override
  Future<void> sendFcmToken(String token) async {
    try {
      final response = await _api
          .getNotificationsApi()
          .notificationsApiGetFcmToken(
            notificationTokenSchema: NotificationTokenSchema(
              (b) => b..fcmToken = token,
            ),
          );

      if (!response.isSuccess) {
        throw ApiException('Failed to send FCM token: ${response.error}', response.statusCode);
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          throw const AuthException('Authentication required');
        } else if (statusCode == 429) {
          throw const ApiException(
            'Too many attempts. Please wait before trying again.',
            429,
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Failed to send FCM token: ${e.toString()}');
    }
  }
}
