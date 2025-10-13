import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/fcm_token_info.dart';
import '../repositories/notification_repository.dart';

/// Use case for syncing FCM token with backend
/// Only sends token if it has changed or hasn't been sent in 3 hours
class SyncFcmTokenUseCase extends UseCase<void, SyncFcmTokenParams> {
  const SyncFcmTokenUseCase(this._repository);

  final NotificationRepository _repository;

  @override
  Future<Result<void>> call(SyncFcmTokenParams params) async {
    // Get stored token info
    final storedInfo = await _repository.getStoredTokenInfo();

    // If token is empty, always send it to clear backend registration (logout case)
    // Otherwise, check if we need to send the token
    final shouldSend =
        params.token.isEmpty ||
        storedInfo == null ||
        storedInfo.token != params.token ||
        storedInfo.needsRefresh;

    if (!shouldSend) {
      Sentry.logger.info('Skipping FCM token sync - token unchanged and fresh');
      return Result.success(null);
    }

    // Send token to backend (can be empty string to clear registration)
    final result = await _repository.sendFcmToken(params.token);

    return result.when(
      success: (_) async {
        if (params.token.isEmpty) {
          // Clear local token info on successful logout
          final clearResult = await _repository.clearTokenInfo();
          return clearResult.when(
            success: (_) => Result.success(null),
            failure: Result.failure,
          );
        } else {
          // Save token info locally on success
          final tokenInfo = FcmTokenInfo(
            token: params.token,
            lastSentAt: DateTime.now(),
          );
          final saveResult = await _repository.saveTokenInfo(tokenInfo);
          return saveResult.when(
            success: (_) => Result.success(null),
            failure: Result.failure,
          );
        }
      },
      failure: (error) => Result.failure(error),
    );
  }
}

/// Parameters for sync FCM token use case
class SyncFcmTokenParams {
  const SyncFcmTokenParams({required this.token});

  final String token;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncFcmTokenParams &&
          runtimeType == other.runtimeType &&
          token == other.token;

  @override
  int get hashCode => token.hashCode;
}
