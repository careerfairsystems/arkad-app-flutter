import 'user.dart';

/// Domain entity representing an authentication session
class AuthSession {
  const AuthSession({
    required this.user,
    required this.token,
    required this.createdAt,
    required this.isValid,
  });

  final User user;
  final String token;
  final DateTime createdAt;
  final bool isValid;

  /// Check if the session is expired (24 hours)
  bool get isExpired => DateTime.now().difference(createdAt).inHours > 24;

  /// Check if the session is still active
  bool get isActive => isValid && !isExpired;

  /// Create a copy with updated values
  AuthSession copyWith({
    User? user,
    String? token,
    DateTime? createdAt,
    bool? isValid,
  }) {
    return AuthSession(
      user: user ?? this.user,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      isValid: isValid ?? this.isValid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthSession &&
          runtimeType == other.runtimeType &&
          user == other.user &&
          token == other.token &&
          isValid == other.isValid;

  @override
  int get hashCode => Object.hash(user, token, isValid);

  @override
  String toString() =>
      'AuthSession(user: ${user.email}, isValid: $isValid, isExpired: $isExpired)';
}
