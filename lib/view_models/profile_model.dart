import 'dart:io';

import 'package:arkad/models/programme.dart';
import 'package:arkad/utils/validation_utils.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../api/extensions.dart';
import '../utils/profile_utils.dart';

/// Provider for handling all profile-related functionality including profile updates
/// and media management
class ProfileModel with ChangeNotifier {
  // Profile update state
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;
  ArkadApi _api = GetIt.I<ArkadApi>();

  // Form data state
  ProfileSchema? _currentUser;

  // Required fields
  final List<String> _requiredFields = [
    'Email',
    'First Name',
    'Last Name',
    'Food Preferences',
  ];

  // Optional fields for validation and UI purposes
  final List<String> _optionalFields = [
    'Profile Picture',
    'Programme',
    'Study Year',
    'Master Title',
    'LinkedIn',
    'CV',
  ];

  // Getters
  bool get isLoading => _isLoading;
  bool get isUploading => _isUploading;
  String? get error => _error;
  ProfileSchema? get currentUser => _currentUser;
  List<String> get requiredFields => _requiredFields;
  List<String> get optionalFields => _optionalFields;
  List<String> get missingRequiredFields => _getMissingFields();

  void initialize(ProfileSchema user) {
    _currentUser = user;
    notifyListeners();
  }

  /// Refresh user profile from API
  Future<bool> refreshProfile() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _api.getUserProfileApi().userModelsApiGetUserProfile();
      
      if (response.isSuccess && response.data != null) {
        _currentUser = response.data!;
        notifyListeners();
        return true;
      } else {
        _setError('Failed to refresh profile: ${response.error}');
        return false;
      }
    } catch (e) {
      _setError('Failed to refresh profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  List<String> _getMissingFields() {
    if (_currentUser == null) return _requiredFields;

    return _requiredFields.where((field) {
      switch (field) {
        case 'Email':
          return _currentUser!.email.isEmpty;
        case 'First Name':
          return _currentUser!.firstName.isEmpty;
        case 'Last Name':
          return _currentUser!.lastName.isEmpty;
        case 'Food Preferences':
          return _currentUser!.foodPreferences?.isEmpty ?? true;
        default:
          return false;
      }
    }).toList();
  }

  /// Update user profile with provided data and optionally upload media files
  Future<bool> updateProfile({
    required UpdateProfileSchema profileData,
    File? profilePicture,
    bool deleteProfilePicture = false,
    File? cv,
    bool deleteCV = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Update profile fields
      final updateResponse = await _api.getUserProfileApi().userModelsApiUpdateProfile(
        updateProfileSchema: profileData,
      );
      
      if (!updateResponse.isSuccess) {
        _setError('Failed to update profile: ${updateResponse.error}');
        return false;
      }

      // Handle profile picture
      if (profilePicture != null) {
        _setUploading(true);
        final picResponse = await _api.getUserProfileApi().userModelsApiUpdateProfilePicture(
          profilePicture: await getMultipartFile(profilePicture),
        );
        if (!picResponse.isSuccess) {
          _setError('Failed to update profile picture: ${picResponse.error}');
          return false;
        }
      } else if (deleteProfilePicture) {
        final deleteResponse = await _api.getUserProfileApi().userModelsApiDeleteProfilePicture();
        if (!deleteResponse.isSuccess) {
          _setError('Failed to delete profile picture: ${deleteResponse.error}');
          return false;
        }
      }

      // Handle CV
      if (cv != null) {
        _setUploading(true);
        final cvResponse = await _api.getUserProfileApi().userModelsApiUpdateCv(
          cv: await getMultipartFile(cv),
        );
        if (!cvResponse.isSuccess) {
          _setError('Failed to update CV: ${cvResponse.error}');
          return false;
        }
      } else if (deleteCV) {
        final deleteCvResponse = await _api.getUserProfileApi().userModelsApiDeleteCv();
        if (!deleteCvResponse.isSuccess) {
          _setError('Failed to delete CV: ${deleteCvResponse.error}');
          return false;
        }
      }

      // If we get here, everything succeeded
      // Update the current user with the response data if available
      if (updateResponse.data != null) {
        _currentUser = updateResponse.data!;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
      _setUploading(false);
    }
  }

  /// Prepare profile data from form inputs
  UpdateProfileSchema prepareProfileData({
    required String firstName,
    required String lastName,
    required Programme? selectedProgramme,
    required String programmeText,
    required String linkedin,
    required String masterTitle,
    required int? studyYear,
    required String foodPreferences,
  }) {
    String formattedLinkedin = formatLinkedInUrl(linkedin);

    final profileMap = ProfileUtils.prepareProfileData(
      firstName: firstName,
      lastName: lastName,
      selectedProgramme: selectedProgramme,
      programmeText: programmeText,
      linkedin: formattedLinkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
      foodPreferences: foodPreferences,
    );

    return UpdateProfileSchema((b) => b
      ..firstName = profileMap['first_name'] as String?
      ..lastName = profileMap['last_name'] as String?
      ..programme = profileMap['programme'] as String?
      ..linkedin = profileMap['linkedin'] as String?
      ..masterTitle = profileMap['master_title'] as String?
      ..studyYear = profileMap['study_year'] as int?
      ..foodPreferences = profileMap['food_preferences'] as String?
    );
  }

  /// Pick a profile image using the centralized image picker
  Future<File?> pickProfileImage(BuildContext context) async {
    try {
      final ImagePicker imagePicker = ImagePicker();
      return await ProfileUtils.pickProfileImage(
        context: context,
        imagePicker: imagePicker,
      );
    } catch (e) {
      _setError('Failed to pick profile image: $e');
      return null;
    }
  }

  /// Pick a CV file using the centralized CV picker
  Future<File?> pickCVFile(BuildContext context) async {
    try {
      return await ProfileUtils.pickCVFile(context: context);
    } catch (e) {
      _setError('Failed to pick CV: $e');
      return null;
    }
  }

  /// Format LinkedIn URL to ensure proper format
  String formatLinkedInUrl(String url) {
    if (url.isEmpty) return '';

    // If URL doesn't start with http or https, assume it's just the username
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      // If it starts with www or linkedin.com, add https
      if (url.startsWith('www.') || url.startsWith('linkedin.com')) {
        return 'https://$url';
      }
      // Otherwise assume it's just the username or profile path
      else {
        // Remove leading @ or / if present
        String username =
            url.startsWith('@') || url.startsWith('/') ? url.substring(1) : url;

        return 'https://linkedin.com/in/$username';
      }
    }

    // URL already has http/https, return as is
    return url;
  }

  // State management helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
