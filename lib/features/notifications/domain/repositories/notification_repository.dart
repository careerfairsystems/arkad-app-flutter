import '../../../../shared/domain/result.dart';
import '../entities/fcm_token_info.dart';

/// Repository interface for notification operations
abstract class NotificationRepository {
  /// Send FCM token to backend
  Future<Result<void>> sendFcmToken(String token);

  /// Get stored FCM token information
  Future<FcmTokenInfo?> getStoredTokenInfo();

  /// Save FCM token information locally
  Future<Result<void>> saveTokenInfo(FcmTokenInfo tokenInfo);

  /// Clear stored token information
  Future<Result<void>> clearTokenInfo();
}
