import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/errors/exception.dart';
import '../../domain/entities/signup_data.dart';
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
          (b) =>
              b
                ..email = email
                ..password = password,
        ),
      );

      if (response.isSuccess && response.data != null) {
        final token = response.data!;
        // Strip "Bearer " prefix if present
        return token.startsWith('Bearer ') ? token.substring(7) : token;
      } else {
        throw ApiException('Sign in failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Incorrect email or password');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many attempts. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Sign in failed: ${e.toString()}');
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
        throw ApiException('Signup failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 415) {
          throw ValidationException(
            'An account with this email already exists',
          );
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many attempts. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Signup failed: ${e.toString()}');
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
        throw ApiException('Signup completion failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 400) {
          throw ValidationException('Invalid verification code');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many attempts. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Signup completion failed: ${e.toString()}');
    }
  }

  @override
  Future<ProfileSchema> getUserProfile() async {
    try {
      final response =
          await _api.getUserProfileApi().userModelsApiGetUserProfile();

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        throw ApiException('Profile loading failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 401) {
          throw AuthException('Authentication required');
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Profile loading failed: ${e.toString()}');
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
        throw ApiException('Password reset failed: ${response.error}');
      }
    } catch (e) {
      if (e is DioException) {
        if (e.response?.statusCode == 404) {
          throw ValidationException('No account found with this email address');
        } else if (e.response?.statusCode == 429) {
          throw ApiException(
            'Too many attempts. Please wait before trying again.',
          );
        }
        throw NetworkException('Network error: ${e.message}');
      }
      throw ApiException('Password reset failed: ${e.toString()}');
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
