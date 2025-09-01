import '../../../../shared/domain/result.dart';
import '../entities/auth_session.dart';
import '../entities/signup_data.dart';
import '../entities/user.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Result<AuthSession>> signIn(String email, String password);

  /// Begin signup process
  Future<Result<String>> beginSignup(SignupData data);

  /// Complete signup with verification code
  Future<Result<AuthSession>> completeSignup(
    String token, 
    String code, 
    SignupData data,
  );

  /// Reset password
  Future<Result<void>> resetPassword(String email);

  /// Refresh current session
  Future<Result<AuthSession>> refreshSession();

  /// Sign out current user
  Future<Result<void>> signOut();

  /// Get current session if exists
  Future<AuthSession?> getCurrentSession();

  /// Update session user data
  Future<Result<void>> updateSessionUser(User user);

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Request new verification code
  Future<Result<void>> requestVerificationCode(String email);
}