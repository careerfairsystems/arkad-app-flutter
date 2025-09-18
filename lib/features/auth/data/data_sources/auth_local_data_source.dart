import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/entities/signup_data.dart';
import '../../domain/entities/user.dart';

/// Abstract interface for auth local data source
abstract class AuthLocalDataSource {
  Future<void> saveSession(AuthSession session);
  Future<AuthSession?> getSession();
  Future<void> clearSession();
  Future<void> saveSignupData(SignupData data, String token);
  Future<SignupData?> getSignupData();
  Future<String?> getSignupToken();
  Future<void> clearSignupData();
  Future<void> updateSessionUser(User user);
}

/// Implementation of auth local data source using secure storage
class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  /// Helper method to strip "Bearer " prefix from tokens
  String _stripBearer(String token) {
    return token.startsWith('Bearer ') ? token.substring(7) : token;
  }

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _sessionValidKey = 'auth_session_valid';
  static const String _sessionCreatedAtKey = 'auth_session_created_at';
  static const String _signupDataKey = 'signup_data';
  static const String _signupTokenKey = 'signup_token';

  @override
  Future<void> saveSession(AuthSession session) async {
    try {
      await Future.wait([
        _secureStorage.write(
          key: _tokenKey,
          value: _stripBearer(session.token),
        ),
        _secureStorage.write(
          key: _userKey,
          value: jsonEncode(_userToJson(session.user)),
        ),
        _secureStorage.write(
          key: _sessionValidKey,
          value: session.isValid.toString(),
        ),
        _secureStorage.write(
          key: _sessionCreatedAtKey,
          value: session.createdAt.toIso8601String(),
        ),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Failed to save session: $e');
    }
  }

  @override
  Future<AuthSession?> getSession() async {
    try {
      final token = await _secureStorage.read(key: _tokenKey);
      final userJson = await _secureStorage.read(key: _userKey);
      final isValidStr = await _secureStorage.read(key: _sessionValidKey);
      final createdAtStr = await _secureStorage.read(key: _sessionCreatedAtKey);

      if (token == null ||
          userJson == null ||
          isValidStr == null ||
          createdAtStr == null) {
        return null;
      }

      final user = _userFromJson(jsonDecode(userJson) as Map<String, dynamic>);
      final isValid = isValidStr.toLowerCase() == 'true';
      final createdAt = DateTime.parse(createdAtStr);

      return AuthSession(
        user: user,
        token: token,
        isValid: isValid,
        createdAt: createdAt,
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      // If there's any error reading session, return null (unauthenticated)
      return null;
    }
  }

  @override
  Future<void> clearSession() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _tokenKey),
        _secureStorage.delete(key: _userKey),
        _secureStorage.delete(key: _sessionValidKey),
        _secureStorage.delete(key: _sessionCreatedAtKey),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      // Ignore errors when clearing - we want to ensure session is gone
    }
  }

  @override
  Future<void> saveSignupData(SignupData data, String token) async {
    try {
      await Future.wait([
        _secureStorage.write(
          key: _signupDataKey,
          value: jsonEncode(_signupDataToJson(data)),
        ),
        _secureStorage.write(key: _signupTokenKey, value: _stripBearer(token)),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Failed to save signup data: $e');
    }
  }

  @override
  Future<SignupData?> getSignupData() async {
    try {
      final dataJson = await _secureStorage.read(key: _signupDataKey);
      if (dataJson == null) return null;

      return _signupDataFromJson(jsonDecode(dataJson) as Map<String, dynamic>);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<String?> getSignupToken() async {
    try {
      return await _secureStorage.read(key: _signupTokenKey);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      return null;
    }
  }

  @override
  Future<void> clearSignupData() async {
    try {
      await Future.wait([
        _secureStorage.delete(key: _signupDataKey),
        _secureStorage.delete(key: _signupTokenKey),
      ]);
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      // Ignore errors when clearing
    }
  }

  @override
  Future<void> updateSessionUser(User user) async {
    try {
      await _secureStorage.write(
        key: _userKey,
        value: jsonEncode(_userToJson(user)),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(e, stackTrace: stackTrace);
      throw Exception('Failed to update session user: $e');
    }
  }

  // Helper methods for JSON serialization
  Map<String, dynamic> _userToJson(User user) {
    return {
      'id': user.id,
      'email': user.email,
      'firstName': user.firstName,
      'lastName': user.lastName,
      'isStudent': user.isStudent,
      'isActive': user.isActive,
      'isStaff': user.isStaff,
      'foodPreferences': user.foodPreferences,
      'programme': user.programme,
      'studyYear': user.studyYear,
      'masterTitle': user.masterTitle,
      'linkedin': user.linkedin,
      'profilePictureUrl': user.profilePictureUrl,
      'cvUrl': user.cvUrl,
    };
  }

  User _userFromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      isStudent: _readBool(json, 'isStudent'),
      isActive: _readBool(json, 'isActive'),
      isStaff: _readBool(json, 'isStaff'),
      foodPreferences: json['foodPreferences'] as String?,
      programme: json['programme'] as String?,
      studyYear: json['studyYear'] as int?,
      masterTitle: json['masterTitle'] as String?,
      linkedin: json['linkedin'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      cvUrl: json['cvUrl'] as String?,
    );
  }

  bool _readBool(Map<String, dynamic> json, String key) {
    final v = json[key];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    if (v is num) return v != 0;
    return false;
  }

  Map<String, dynamic> _signupDataToJson(SignupData data) {
    return {
      'email': data.email,
      // Password intentionally excluded from storage for security
      'firstName': data.firstName,
      'lastName': data.lastName,
      'foodPreferences': data.foodPreferences,
    };
  }

  SignupData _signupDataFromJson(Map<String, dynamic> json) {
    return SignupData(
      email: json['email'] as String,
      password: '', // Password not stored, empty string as placeholder
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      foodPreferences: json['foodPreferences'] as String?,
    );
  }
}
