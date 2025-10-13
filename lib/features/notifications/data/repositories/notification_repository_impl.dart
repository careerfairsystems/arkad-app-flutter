import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/exception.dart';
import '../../domain/entities/fcm_token_info.dart';
import '../../domain/repositories/notification_repository.dart';
import '../data_sources/notification_local_data_source.dart';
import '../data_sources/notification_remote_data_source.dart';

/// Implementation of notification repository
class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
  );

  final NotificationRemoteDataSource _remoteDataSource;
  final NotificationLocalDataSource _localDataSource;

  @override
  Future<Result<void>> sendFcmToken(String token) async {
    final isLogout = token.isEmpty;

    Sentry.logger.info(
      isLogout
          ? 'Repository: Sending empty FCM token (logout)'
          : 'Repository: Sending FCM token to API',
      attributes: {
        'token_length': SentryLogAttribute.int(token.length),
        'is_logout': SentryLogAttribute.bool(isLogout),
      },
    );

    try {
      await _remoteDataSource.sendFcmToken(token);

      Sentry.logger.info(
        isLogout
            ? 'Repository: Empty FCM token sent successfully (logout)'
            : 'Repository: FCM token sent successfully',
      );

      return Result.success(null);
    } on AuthException catch (e) {
      Sentry.logger.fmt.info(
        'Repository: Auth exception while sending FCM token: %s',
        [e.message],
      );
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Auth exception in sendFcmToken: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(AuthenticationError(details: e.message));
    } on NetworkException catch (e) {
      Sentry.logger.fmt.info(
        'Repository: Network exception while sending FCM token: %s',
        [e.message],
      );
      await Sentry.captureMessage(
        'Send FCM token failed - network unavailable',
        level: SentryLevel.warning,
      );
      await Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Network exception in sendFcmToken: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.statusCode == 429) {
        Sentry.logger.error(
          'Repository: Rate limit exceeded while sending FCM token',
        );
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 5)));
      }
      Sentry.logger.fmt.error(
        'Repository: API exception while sending FCM token: %s',
        [e.message],
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      Sentry.logger.fmt.error(
        'Repository: Unknown exception while sending FCM token: %s',
        [e.toString()],
      );
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<FcmTokenInfo?> getStoredTokenInfo() async {
    try {
      return await _localDataSource.getTokenInfo();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<Result<void>> saveTokenInfo(FcmTokenInfo tokenInfo) async {
    try {
      await _localDataSource.saveTokenInfo(tokenInfo);
      return Result.success(null);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> clearTokenInfo() async {
    try {
      await _localDataSource.clearTokenInfo();
      return Result.success(null);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }
}
