/// Domain entity representing FCM token information
class FcmTokenInfo {
  const FcmTokenInfo({required this.token, required this.lastSentAt});

  final String token;
  final DateTime lastSentAt;

  /// Check if token needs to be resent (3 hours threshold)
  bool get needsRefresh => DateTime.now().difference(lastSentAt).inHours >= 3;

  /// Create a copy with updated values
  FcmTokenInfo copyWith({String? token, DateTime? lastSentAt}) {
    return FcmTokenInfo(
      token: token ?? this.token,
      lastSentAt: lastSentAt ?? this.lastSentAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FcmTokenInfo &&
          runtimeType == other.runtimeType &&
          token == other.token &&
          lastSentAt == other.lastSentAt;

  @override
  int get hashCode => Object.hash(token, lastSentAt);

  @override
  String toString() =>
      'FcmTokenInfo(token: ${token.substring(0, 10)}..., lastSentAt: $lastSentAt)';
}
