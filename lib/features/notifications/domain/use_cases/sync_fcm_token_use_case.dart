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
    if (params.token.isEmpty) {
      return Result.success(null);
    }

    // Get stored token info
    final storedInfo = await _repository.getStoredTokenInfo();

    // Check if we need to send the token
    final shouldSend =
        storedInfo == null ||
        storedInfo.token != params.token ||
        storedInfo.needsRefresh;

    if (!shouldSend) {
      return Result.success(null);
    }

    // Send token to backend
    final result = await _repository.sendFcmToken(params.token);

    return result.when(
      success: (_) async {
        // Save token info locally on success
        final tokenInfo = FcmTokenInfo(
          token: params.token,
          lastSentAt: DateTime.now(),
        );
        await _repository.saveTokenInfo(tokenInfo);
        return Result.success(null);
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
