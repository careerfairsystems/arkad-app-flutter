import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../../../shared/errors/exception.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_local_data_source.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../mappers/user_mapper.dart';

/// Implementation of auth repository
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async {
    try {
      // Attempt sign in via remote API
      final token = await _remoteDataSource.signIn(email, password);

      // Set auth token for subsequent API calls
      _remoteDataSource.setBearerAuth("AuthBearer", token);

      // Load user profile
      final userDto = await _remoteDataSource.getUserProfile();
      final user = UserMapper.fromDto(userDto);

      // Create session
      final session = AuthSession(
        user: user,
        token: token,
        createdAt: DateTime.now(),
        isValid: true,
      );

      // Save session locally
      await _localDataSource.saveSession(session);

      return Result.success(session);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Sign in failed - invalid credentials',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Auth exception in signIn: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(SignInError(details: e.message));
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Validation error in signIn: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Sign in failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Network exception in signIn: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Rate limit hit in signIn: ${e.message}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(RateLimitError(const Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<String>> beginSignup(SignupData data) async {
    try {
      final token = await _remoteDataSource.beginSignup(data);

      // Save signup data and token for later use
      await _localDataSource.saveSignupData(data, token);

      return Result.success(token);
    } on ValidationException catch (e, stackTrace) {
      if (e.message.contains('already exists')) {
        // Email exists is expected validation error - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Email already exists in beginSignup: ${data.email}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(EmailExistsError(data.email));
      }
      // Other validation errors are expected - record as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Validation error in beginSignup: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Signup begin failed - network unavailable',
        level: SentryLevel.warning,
      );
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Network exception in beginSignup: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Rate limit hit in beginSignup: ${e.message}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(RateLimitError(const Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> completeSignup(
    String token,
    String code,
    SignupData data,
  ) async {
    try {
      // Complete signup via remote API
      await _remoteDataSource.completeSignup(token, code, data);

      // Clear signup data as it's no longer needed
      await _localDataSource.clearSignupData();

      // Now sign in to get the auth token
      final signInResult = await signIn(data.email, data.password);
      return signInResult;
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Validation error: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Network unavailable',
        level: SentryLevel.warning,
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Rate limit hit: ${e.message}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(RateLimitError(const Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _remoteDataSource.resetPassword(email);
      return Result.success(null);
    } on ValidationException catch (e, stackTrace) {
      // Validation errors are expected domain errors - record as breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Validation error: ${e.message}',
          level: SentryLevel.info,
        ),
      );
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Network unavailable',
        level: SentryLevel.warning,
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Rate limit hit: ${e.message}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(RateLimitError(const Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<AuthSession>> refreshSession() async {
    try {
      final session = await getCurrentSession();
      if (session == null) {
        return Result.failure(const AuthenticationError());
      }

      // Set the existing token for API calls
      _remoteDataSource.setBearerAuth("AuthBearer", session.token);

      // Try to refresh user profile
      final userDto = await _remoteDataSource.getUserProfile();
      final user = UserMapper.fromDto(userDto);

      // Update session with fresh user data
      final refreshedSession = session.copyWith(user: user);
      await _localDataSource.saveSession(refreshedSession);

      return Result.success(refreshedSession);
    } on AuthException catch (e, stackTrace) {
      // Auth errors are expected domain errors - log as warning
      await Sentry.captureMessage(
        'Session refresh failed - authentication required',
        level: SentryLevel.warning,
      );
      // If refresh fails due to auth, clear local session
      await _localDataSource.clearSession();
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e, stackTrace) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Session refresh failed - network unavailable',
        level: SentryLevel.warning,
      );
      return Result.failure(NetworkError(details: e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      // Clear local session
      await _localDataSource.clearSession();

      // Clear API auth
      _remoteDataSource.clearAuth();

      return Result.success(null);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<AuthSession?> getCurrentSession() async {
    try {
      return await _localDataSource.getSession();
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<Result<void>> updateSessionUser(User user) async {
    try {
      await _localDataSource.updateSessionUser(user);
      return Result.success(null);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      final session = await getCurrentSession();
      return session?.isActive ?? false;
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return false;
    }
  }

  @override
  Future<Result<String>> requestVerificationCode(String email) async {
    try {
      // Get stored signup data to resend verification
      final signupData = await _localDataSource.getSignupData();
      if (signupData == null || signupData.email != email) {
        return Result.failure(
          const ValidationError("No pending signup found for this email"),
        );
      }

      // Request new verification code by re-initiating signup
      final newToken = await _remoteDataSource.beginSignup(signupData);

      // Update stored token with the new one
      await _localDataSource.saveSignupData(signupData, newToken);

      return Result.success(newToken);
    } on ValidationException catch (e) {
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - log as warning
      await Sentry.captureMessage(
        'Network unavailable',
        level: SentryLevel.warning,
      );
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      if (e.message.contains('429')) {
        // Rate limit errors are expected - record as breadcrumb
        Sentry.addBreadcrumb(
          Breadcrumb(
            message: 'Rate limit hit: ${e.message}',
            level: SentryLevel.info,
          ),
        );
        return Result.failure(RateLimitError(const Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }
}
