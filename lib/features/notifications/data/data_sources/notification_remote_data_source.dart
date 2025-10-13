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
    final isLogout = token.isEmpty;

    Sentry.logger.info(
      isLogout
          ? 'DataSource: Making API call to send empty FCM token (logout)'
          : 'DataSource: Making API call to send FCM token',
      attributes: {
        'token_length': SentryLogAttribute.int(token.length),
        'is_logout': SentryLogAttribute.bool(isLogout),
        'endpoint': SentryLogAttribute.string('/api/notifications/fcm-token'),
      },
    );

    try {
      final response = await _api
          .getNotificationsApi()
          .notificationsApiUpdateFcmToken(
            updateFCMTokenSchema: UpdateFCMTokenSchema(
              (b) => b..fcmToken = token,
            ),
          );

      if (!response.isSuccess) {
        Sentry.logger.fmt.error(
          'DataSource: API returned non-success status: %s',
          [response.statusCode.toString()],
          attributes: {
            'status_code': SentryLogAttribute.int(response.statusCode ?? 0),
            'error_message': SentryLogAttribute.string(response.error),
            'is_logout': SentryLogAttribute.bool(isLogout),
          },
        );
        throw ApiException(
          'Failed to send FCM token: ${response.error}',
          response.statusCode,
        );
      }

      Sentry.logger.info(
        isLogout
            ? 'DataSource: API call successful - empty token sent (logout)'
            : 'DataSource: API call successful - FCM token sent',
        attributes: {
          'status_code': SentryLogAttribute.int(response.statusCode ?? 0),
        },
      );
    } catch (e) {
      await Sentry.captureException(e);

      if (e is DioException) {
        final statusCode = e.response?.statusCode;

        Sentry.logger.fmt.error(
          'DataSource: DioException while sending FCM token: %s',
          [e.message ?? 'Unknown error'],
          attributes: {
            'status_code': SentryLogAttribute.int(statusCode ?? 0),
            'dio_error_type': SentryLogAttribute.string(e.type.toString()),
            'is_logout': SentryLogAttribute.bool(isLogout),
          },
        );

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

      Sentry.logger.fmt.error(
        'DataSource: Exception while sending FCM token: %s',
        [e.toString()],
        attributes: {
          'exception_type': SentryLogAttribute.string(e.runtimeType.toString()),
          'is_logout': SentryLogAttribute.bool(isLogout),
        },
      );

      throw ApiException('Failed to send FCM token: ${e.toString()}');
    }
  }
}
