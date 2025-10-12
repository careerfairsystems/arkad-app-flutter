import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/errors/exception.dart';
import '../../domain/entities/signup_data.dart';
import '../handlers/auth_error_handler.dart';
import '../mappers/signup_mapper.dart';

/// Abstract interface for auth remote data source
abstract class AuthRemoteDataSource {
  Future<String> signIn(String email, String password);
  Future<String> beginSignup(SignupData data);
  Future<ProfileSchema> completeSignup(
    String token,
    String code,
    SignupData data,
  );
  Future<ProfileSchema> getUserProfile();
  Future<void> resetPassword(String email);
  void setBearerAuth(String name, String token);
  void clearAuth();
}

/// Implementation of auth remote data source using auto-generated API client
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  const AuthRemoteDataSourceImpl(this._api);

  final ArkadApi _api;

  @override
  Future<String> signIn(String email, String password) async {
    try {
      final response = await _api.getAuthenticationApi().userModelsApiSignin(
        signinSchema: SigninSchema(
          (b) => b
            ..email = email
            ..password = password,
        ),
      );

      if (response.isSuccess && response.data != null) {
        final token = response.data!;
        // Strip "Bearer " prefix if present
        return token.startsWith('Bearer ') ? token.substring(7) : token;
      } else {
        throw ApiException(
          'Sign in failed: ${response.error}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Use AuthErrorHandler for consistent error mapping and logging
      final exception = await AuthErrorHandler.handleDioException(
        e,
        operation: 'signIn',
      );
      throw exception;
    } catch (e) {
      // Unexpected non-Dio errors
      await Sentry.captureException(e);
      throw ApiException('Unexpected error during sign in: ${e.toString()}');
    }
  }

  @override
  Future<String> beginSignup(SignupData data) async {
    try {
      final response = await _api
          .getAuthenticationApi()
          .userModelsApiBeginSignup(
            signupSchema: SignupMapper.toSignupDto(data),
          );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(
          'Signup failed: ${response.error}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Use AuthErrorHandler for consistent error mapping and logging
      final exception = await AuthErrorHandler.handleDioException(
        e,
        operation: 'beginSignup',
        additionalContext: {'email_domain': data.email.split('@').last},
      );
      throw exception;
    } catch (e) {
      // Unexpected non-Dio errors
      await Sentry.captureException(e);
      throw ApiException('Unexpected error during signup: ${e.toString()}');
    }
  }

  @override
  Future<ProfileSchema> completeSignup(
    String token,
    String code,
    SignupData data,
  ) async {
    try {
      final response = await _api
          .getAuthenticationApi()
          .userModelsApiCompleteSignup(
            completeSignupSchema: SignupMapper.toCompleteSignupDto(
              token: token,
              code: code,
              data: data,
            ),
          );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(
          'Signup completion failed: ${response.error}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Use AuthErrorHandler for consistent error mapping and logging
      final exception = await AuthErrorHandler.handleDioException(
        e,
        operation: 'completeSignup',
        additionalContext: {'has_code': code.isNotEmpty.toString()},
      );
      throw exception;
    } catch (e) {
      // Unexpected non-Dio errors
      await Sentry.captureException(e);
      throw ApiException(
        'Unexpected error during signup completion: ${e.toString()}',
      );
    }
  }

  @override
  Future<ProfileSchema> getUserProfile() async {
    try {
      final response = await _api
          .getUserProfileApi()
          .userModelsApiGetUserProfile();

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException(
          'Profile loading failed: ${response.error}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Use AuthErrorHandler for consistent error mapping and logging
      final exception = await AuthErrorHandler.handleDioException(
        e,
        operation: 'getUserProfile',
      );
      throw exception;
    } catch (e) {
      // Unexpected non-Dio errors
      await Sentry.captureException(e);
      throw ApiException('Unexpected error loading profile: ${e.toString()}');
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      final response = await _api
          .getAuthenticationApi()
          .userModelsApiResetPassword(
            resetPasswordSchema: ResetPasswordSchema((b) => b..email = email),
          );

      if (!response.isSuccess) {
        throw ApiException(
          'Password reset failed: ${response.error}',
          response.statusCode,
        );
      }
    } on DioException catch (e) {
      // Use AuthErrorHandler for consistent error mapping and logging
      final exception = await AuthErrorHandler.handleDioException(
        e,
        operation: 'resetPassword',
        additionalContext: {'email_domain': email.split('@').last},
      );
      throw exception;
    } catch (e) {
      // Unexpected non-Dio errors
      await Sentry.captureException(e);
      throw ApiException(
        'Unexpected error during password reset: ${e.toString()}',
      );
    }
  }

  @override
  void setBearerAuth(String name, String token) {
    _api.setBearerAuth(name, token);
  }

  @override
  void clearAuth() {
    _api.setApiKey('AuthBearer', '');
  }
}
