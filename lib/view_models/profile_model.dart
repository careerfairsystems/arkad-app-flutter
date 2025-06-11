import 'dart:io';

import 'package:arkad/models/programme.dart';
import 'package:arkad/utils/validation_utils.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../utils/profile_utils.dart';
import '../utils/service_helper.dart';

const String _profilePictureField = 'profile_picture';
const String _cvField = 'cv';

extension ProfileSchemaExtension on ProfileSchema {
  // Get missing required fields
  List<String> getMissingFields() {
    List<String> missingFields = [];

    if (firstName == null || firstName!.isEmpty) {
      missingFields.add('First Name');
    }
    if (lastName == null || lastName!.isEmpty) missingFields.add('Last Name');
    if (programme == null || programme!.isEmpty) missingFields.add('Programme');
    if (studyYear == null) missingFields.add('Study Year');
    if (foodPreferences == null || foodPreferences!.isEmpty) {
      missingFields.add('Food Preferences');
    }

    // CV, profile picture, LinkedIn, and master title are no longer in missing fields list
    return missingFields;
  }

  bool get isVerified {
    return firstName != null &&
        firstName!.isNotEmpty &&
        lastName != null &&
        lastName!.isNotEmpty &&
        programme != null &&
        programme!.isNotEmpty &&
        studyYear != null &&
        foodPreferences != null &&
        foodPreferences!.isNotEmpty;
  }
}

/// Comprehensive provider for handling all profile-related functionality
/// including onboarding, profile updates, and media management
class ProfileModel with ChangeNotifier {
  // State variables for onboarding
  int _currentStep = 0;
  bool _onboardingCompleted = false;
  int _totalSteps = 0;
  List<String> _missingRequiredFields = [];
  List<String> _optionalFields = [];
  List<String> _completedOptionalFields = [];

  // Profile update state
  bool _isLoading = false;
  bool _isUploading = false;
  String? _error;

  // Form data state (for centralized access)
  ProfileSchema? _currentUser;

  ArkadApi _api = GetIt.I<ArkadApi>();

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
  ProfileSchema? get user => _currentUser;

  // Calculate completion percentage including both required and optional fields
  double get completionPercentage {
    int totalFields = _steps.fold(0, (total, step) {
      return total +
          (step['requiredFields'].length as int) +
          (step['optionalFields'].length as int);
    });

    int missingFields =
        _missingRequiredFields.length +
        (_optionalFields.length - _completedOptionalFields.length);

    return totalFields > 0 ? (totalFields - missingFields) / totalFields : 1.0;
  }

  // Initialize provider by loading saved data
  Future<void> initialize() async {
    _setLoading(true);

    try {
      final user = await _api.getUserProfileApi().userModelsApiGetUserProfile();
      final prefs = await SharedPreferences.getInstance();

      // Get saved step or default to 0
      _currentStep = prefs.getInt(_currentStepKey) ?? 0;
      _onboardingCompleted = prefs.getBool(_onboardingCompletedKey) ?? false;

      // Update fields based on current user data
      _updateFields(user.data!);
      _currentUser = user.data!;
    } catch (e) {
      print('Error initializing profile provider: $e');
      _setError('Failed to initialize profile: $e');

      // Use default values if initialization fails
      _currentStep = 0;
      _onboardingCompleted = false;
      _updateFields(user);
    } finally {
      _setLoading(false);
    }
  }

  // Update fields when user data changes
  void _updateFields(ProfileSchema? user) {
    if (user == null) {
      _missingRequiredFields = [];
      _optionalFields = [];
      _completedOptionalFields = [];
      _totalSteps = 0;
      _currentUser = null;
      notifyListeners();
      return;
    }

    // Store current user
    _currentUser = user;
    notifyListeners();
  }

  // Refresh onboarding state based on updated user data
  Future<void> refreshOnboardingState(ProfileSchema? user) async {
    _updateFields(user);
    notifyListeners();
  }

  /// Update user profile with provided data and optionally upload media files
  Future<bool> updateProfile({
    required profileData,
    File? profilePicture,
    bool deleteProfilePicture = false,
    File? cv,
    bool deleteCV = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Update profile fields
      await _api.getUserProfileApi().userModelsApiUpdateProfile(
        updateProfileSchema: profileData,
      );

      // Handle profile picture
      if (profilePicture != null) {
        _setUploading(true);
        await _api.getUserProfileApi().userModelsApiUpdateProfilePicture(
          profilePicture: await getMultipartFile(profilePicture),
        );
      } else if (deleteProfilePicture) {
        await _api.getUserProfileApi().userModelsApiDeleteProfilePicture();
      }

      // Handle CV
      if (cv != null) {
        _setUploading(true);
        await _api.getUserProfileApi().userModelsApiUpdateCv(
          cv: await getMultipartFile(cv),
        );
      } else if (deleteCV) {
        await _api.getUserProfileApi().userModelsApiDeleteCv();
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
  Map<String, dynamic> prepareProfileData({
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

    return ProfileUtils.prepareProfileData(
      firstName: firstName,
      lastName: lastName,
      selectedProgramme: selectedProgramme,
      programmeText: programmeText,
      linkedin: formattedLinkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
      foodPreferences: foodPreferences,
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
