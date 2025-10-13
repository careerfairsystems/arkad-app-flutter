import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/error_mapper.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/sync_fcm_token_use_case.dart';

class SyncFcmTokenCommand
    extends ParameterizedCommand<SyncFcmTokenParams, void> {
  SyncFcmTokenCommand(this._syncFcmTokenUseCase);

  final SyncFcmTokenUseCase _syncFcmTokenUseCase;

  @override
  Future<void> executeWithParams(SyncFcmTokenParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    // Log token sync attempt
    final tokenType = params.token.isEmpty ? 'empty (logout)' : 'valid';
    await Sentry.logger.info(
      'Starting FCM token sync with $tokenType token',
      attributes: {
        'token_type': SentryLogAttribute.string(tokenType),
        'token_length': SentryLogAttribute.int(params.token.length),
      },
    );

    try {
      final result = await _syncFcmTokenUseCase.call(params);

      result.when(
        success: (_) {
          Sentry.logger.info(
            'FCM token sync completed successfully',
            attributes: {'token_type': SentryLogAttribute.string(tokenType)},
          );
          setResult(null);
        },
        failure: (error) {
          Sentry.logger.fmt.error(
            'FCM token sync failed: %s',
            [error.userMessage],
            attributes: {
              'token_type': SentryLogAttribute.string(tokenType),
              'error_type': SentryLogAttribute.string(
                error.runtimeType.toString(),
              ),
            },
          );
          setError(error);
        },
      );
    } catch (e) {
      Sentry.logger.fmt.error(
        'FCM token sync threw exception: %s',
        [e.toString()],
        attributes: {
          'token_type': SentryLogAttribute.string(tokenType),
          'exception_type': SentryLogAttribute.string(e.runtimeType.toString()),
        },
      );

      if (e is DioException) {
        setError(
          ErrorMapper.fromDioException(
            e,
            null,
            operationContext: 'sync_fcm_token',
          ),
        );
      } else {
        setError(
          ErrorMapper.fromException(
            e,
            null,
            operationContext: 'sync_fcm_token',
          ),
        );
      }
    } finally {
      setExecuting(false);
    }
  }

  /// Sync FCM token with backend
  Future<void> syncToken(String token) async {
    await executeWithParams(SyncFcmTokenParams(token: token));
  }
}
