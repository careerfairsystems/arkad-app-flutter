import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/data/repositories/base_repository.dart';
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
class AuthRepositoryImpl extends BaseRepository implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;

  @override
  Future<Result<AuthSession>> signIn(String email, String password) async {
    Sentry.logger.info(
      'Starting sign in',
      attributes: {
        'operation': SentryLogAttribute.string('signIn'),
        'email_domain': SentryLogAttribute.string(email.split('@').last),
      },
    );

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

      Sentry.logger.info(
        'Sign in successful',
        attributes: {
          'operation': SentryLogAttribute.string('signIn'),
        },
      );

      return Result.success(session);
    } on AuthException catch (e) {
      // Auth errors are expected - already logged in data source
      return Result.failure(SignInError(details: e.message));
    } on ValidationException catch (e) {
      // Validation errors are expected - already logged in data source
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
      return Result.failure(NetworkError(details: e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<String>> beginSignup(SignupData data) async {
    Sentry.logger.info(
      'Starting signup',
      attributes: {
        'operation': SentryLogAttribute.string('beginSignup'),
        'email_domain': SentryLogAttribute.string(data.email.split('@').last),
      },
    );

    try {
      final token = await _remoteDataSource.beginSignup(data);

      // Save signup data (excluding password for security) and token to secure storage
      await _localDataSource.saveSignupData(data, token);

      Sentry.logger.info(
        'Signup verification email sent',
        attributes: {'operation': SentryLogAttribute.string('beginSignup')},
      );

      return Result.success(token);
    } on ApiException catch (e, stackTrace) {
      // Check status code for specific error types
      if (e.statusCode == 409) {
        // Email already exists (per API spec)
        return Result.failure(EmailExistsError(data.email));
      } else if (e.statusCode == 406) {
        // Password validation failed (per API spec)
        return Result.failure(
          ValidationError(
            e.message.isEmpty
                ? 'Password does not meet requirements'
                : e.message,
          ),
        );
      } else if (e.statusCode == 429) {
        // Rate limiting
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 5)));
      }
      // Other API errors
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } on ValidationException catch (e) {
      // Validation errors
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
      return Result.failure(NetworkError(details: e.message));
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
    Sentry.logger.info(
      'Completing signup verification',
      attributes: {
        'operation': SentryLogAttribute.string('completeSignup'),
        'has_code': SentryLogAttribute.string(code.isNotEmpty.toString()),
      },
    );

    try {
      // Complete signup via remote API
      await _remoteDataSource.completeSignup(token, code, data);

      // Clear signup data as it's no longer needed
      await _localDataSource.clearSignupData();

      Sentry.logger.info(
        'Signup verification successful, signing in',
        attributes: {'operation': SentryLogAttribute.string('completeSignup')},
      );

      // Now sign in to get the auth token
      final signInResult = await signIn(data.email, data.password);
      return signInResult;
    } on ValidationException catch (e) {
      // Validation errors are expected - already logged in data source
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
      return Result.failure(NetworkError(details: e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    Sentry.logger.info(
      'Starting password reset',
      attributes: {
        'operation': SentryLogAttribute.string('resetPassword'),
        'email_domain': SentryLogAttribute.string(email.split('@').last),
      },
    );

    try {
      await _remoteDataSource.resetPassword(email);

      Sentry.logger.info(
        'Password reset email sent',
        attributes: {'operation': SentryLogAttribute.string('resetPassword')},
      );

      return Result.success(null);
    } on ValidationException catch (e) {
      // Validation errors are expected - already logged in data source
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      // Check status code instead of string matching
      if (e.statusCode == 429) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 5)));
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
    Sentry.logger.info(
      'Refreshing session',
      attributes: {'operation': SentryLogAttribute.string('refreshSession')},
    );

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

      Sentry.logger.info(
        'Session refreshed successfully',
        attributes: {
          'operation': SentryLogAttribute.string('refreshSession'),
        },
      );

      return Result.success(refreshedSession);
    } on AuthException catch (e) {
      // Auth errors are expected - clear session and require re-login
      await _localDataSource.clearSession();
      return Result.failure(ProfileLoadingError(details: e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
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
      final session = await _localDataSource.getSession();

      // If session exists, set the bearer token for API calls
      if (session != null && session.isActive) {
        _remoteDataSource.setBearerAuth("AuthBearer", session.token);
      }

      return session;
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
  Future<Result<String>> requestVerificationCode(SignupData signupData) async {
    Sentry.logger.info(
      'Requesting new verification code',
      attributes: {
        'operation': SentryLogAttribute.string('requestVerificationCode'),
        'email_domain': SentryLogAttribute.string(
          signupData.email.split('@').last,
        ),
      },
    );

    try {
      // Request new verification code by re-initiating signup with full signup data
      // This uses the SignupData passed from the ViewModel which has the password in memory
      final newToken = await _remoteDataSource.beginSignup(signupData);

      // Update stored token with the new one
      await _localDataSource.saveSignupData(signupData, newToken);

      Sentry.logger.info(
        'New verification code sent',
        attributes: {
          'operation': SentryLogAttribute.string('requestVerificationCode'),
        },
      );

      return Result.success(newToken);
    } on ValidationException catch (e) {
      // Validation errors are expected - already logged in data source
      return Result.failure(ValidationError(e.message));
    } on NetworkException catch (e) {
      // Network errors are expected - already logged in data source
      return Result.failure(NetworkError(details: e.message));
    } on ApiException catch (e, stackTrace) {
      // Handle rate limiting errors
      if (e.statusCode == 429) {
        await Sentry.captureException(e, stackTrace: stackTrace);
        return Result.failure(const RateLimitError(Duration(minutes: 5)));
      }
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.message));
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return Result.failure(UnknownError(e.toString()));
    }
  }
}
