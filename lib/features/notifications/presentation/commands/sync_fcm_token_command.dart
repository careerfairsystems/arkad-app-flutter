import 'package:dio/dio.dart';

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

    try {
      final result = await _syncFcmTokenUseCase.call(params);

      result.when(
        success: (_) => setResult(null),
        failure: (error) => setError(error),
      );
    } catch (e) {
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
