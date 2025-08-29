import '../../features/auth/domain/entities/auth_session.dart';
import '../../features/auth/domain/entities/user.dart';

/// Event fired when authentication session changes
class AuthSessionChangedEvent {
  const AuthSessionChangedEvent(this.session);
  
  final AuthSession session;
  
  @override
  String toString() => 'AuthSessionChangedEvent(user: ${session.user.email})';
}

/// Event fired when user logs out
class UserLoggedOutEvent {
  const UserLoggedOutEvent();
  
  @override
  String toString() => 'UserLoggedOutEvent()';
}

/// Event fired when user session is refreshed
class UserSessionRefreshedEvent {
  const UserSessionRefreshedEvent(this.user);
  
  final User user;
  
  @override
  String toString() => 'UserSessionRefreshedEvent(user: ${user.email})';
}