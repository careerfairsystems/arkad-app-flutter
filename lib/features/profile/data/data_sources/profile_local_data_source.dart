import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/profile.dart';
import '../../domain/entities/programme.dart';

/// Abstract interface for profile local data source
abstract class ProfileLocalDataSource {
  Future<void> saveProfile(Profile profile);
  Future<Profile?> getProfile();
  Future<void> clearProfile();
  Future<void> saveCachedProgrammes(List<String> programmes);
  Future<List<String>?> getCachedProgrammes();
}

/// Implementation of profile local data source using secure storage
class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  const ProfileLocalDataSourceImpl(this._secureStorage);

  final FlutterSecureStorage _secureStorage;

  static const String _profileKey = 'cached_profile';
  static const String _programmesKey = 'cached_programmes';

  @override
  Future<void> saveProfile(Profile profile) async {
    try {
      await _secureStorage.write(
        key: _profileKey,
        value: jsonEncode(_profileToJson(profile)),
      );
    } catch (e) {
      throw Exception('Failed to save profile: $e');
    }
  }

  @override
  Future<Profile?> getProfile() async {
    try {
      final profileJson = await _secureStorage.read(key: _profileKey);
      if (profileJson == null) return null;

      return _profileFromJson(jsonDecode(profileJson) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> clearProfile() async {
    try {
      await _secureStorage.delete(key: _profileKey);
    } catch (e) {
      // Ignore errors when clearing
    }
  }

  @override
  Future<void> saveCachedProgrammes(List<String> programmes) async {
    try {
      await _secureStorage.write(
        key: _programmesKey,
        value: jsonEncode(programmes),
      );
    } catch (e) {
      throw Exception('Failed to save programmes: $e');
    }
  }

  @override
  Future<List<String>?> getCachedProgrammes() async {
    try {
      final programmesJson = await _secureStorage.read(key: _programmesKey);
      if (programmesJson == null) return null;

      final List<dynamic> programmesList = jsonDecode(programmesJson) as List<dynamic>;
      return programmesList.cast<String>();
    } catch (e) {
      return null;
    }
  }

  // Helper methods for JSON serialization
  Map<String, dynamic> _profileToJson(Profile profile) {
    return {
      'id': profile.id,
      'email': profile.email,
      'firstName': profile.firstName,
      'lastName': profile.lastName,
      'foodPreferences': profile.foodPreferences,
      'programme': ProgrammeUtils.programmeToLabel(profile.programme),
      'studyYear': profile.studyYear,
      'masterTitle': profile.masterTitle,
      'linkedin': profile.linkedin,
      'profilePictureUrl': profile.profilePictureUrl,
      'cvUrl': profile.cvUrl,
    };
  }

  Profile _profileFromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as int,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      foodPreferences: json['foodPreferences'] as String?,
      programme: ProgrammeUtils.labelToProgramme(json['programme'] as String?),
      studyYear: json['studyYear'] as int?,
      masterTitle: json['masterTitle'] as String?,
      linkedin: json['linkedin'] as String?,
      profilePictureUrl: json['profilePictureUrl'] as String?,
      cvUrl: json['cvUrl'] as String?,
    );
  }
}