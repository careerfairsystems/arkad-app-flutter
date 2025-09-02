import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/events/profile_events.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/get_current_profile_use_case.dart';
import '../../domain/use_cases/update_profile_use_case.dart';
import '../../domain/use_cases/upload_cv_use_case.dart';
import '../../domain/use_cases/upload_profile_picture_use_case.dart';
import '../commands/get_profile_command.dart';
import '../commands/update_profile_command.dart';
import '../commands/upload_cv_command.dart';
import '../commands/upload_profile_picture_command.dart';

/// Profile presentation layer following clean architecture
/// Coordinates UI state and business operations through commands and use cases
class ProfileViewModel extends ChangeNotifier {
  // Stream subscriptions for authentication events
  StreamSubscription? _authSessionSubscription;
  StreamSubscription? _logoutSubscription;
  final GetCurrentProfileUseCase _getCurrentProfileUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final UploadProfilePictureUseCase _uploadProfilePictureUseCase;
  final UploadCVUseCase _uploadCVUseCase;

  // Commands for UI operations
  late final GetProfileCommand _getProfileCommand;
  late final UpdateProfileCommand _updateProfileCommand;
  late final UploadProfilePictureCommand _uploadProfilePictureCommand;
  late final UploadCVCommand _uploadCVCommand;

  // Current profile state
  Profile? _currentProfile;
  AppError? _error;

  ProfileViewModel({
    required GetCurrentProfileUseCase getCurrentProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadProfilePictureUseCase uploadProfilePictureUseCase,
    required UploadCVUseCase uploadCVUseCase,
  })  : _getCurrentProfileUseCase = getCurrentProfileUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _uploadProfilePictureUseCase = uploadProfilePictureUseCase,
        _uploadCVUseCase = uploadCVUseCase {
    _initializeCommands();
    _subscribeToAuthEvents();
    // Profile will be loaded when explicitly requested or after auth success
  }

  void _initializeCommands() {
    _getProfileCommand = GetProfileCommand(_getCurrentProfileUseCase);
    _updateProfileCommand = UpdateProfileCommand(_updateProfileUseCase);
    _uploadProfilePictureCommand = UploadProfilePictureCommand(_uploadProfilePictureUseCase);
    _uploadCVCommand = UploadCVCommand(_uploadCVUseCase);

    // Listen to command changes
    _getProfileCommand.addListener(_onCommandStateChanged);
    _updateProfileCommand.addListener(_onCommandStateChanged);
    _uploadProfilePictureCommand.addListener(_onCommandStateChanged);
    _uploadCVCommand.addListener(_onCommandStateChanged);
  }

  void _onCommandStateChanged() {
    // Update current profile if any command successfully loaded it
    if (_getProfileCommand.isCompleted && _getProfileCommand.result != null) {
      _currentProfile = _getProfileCommand.result;
    } else if (_updateProfileCommand.isCompleted && _updateProfileCommand.result != null) {
      _currentProfile = _updateProfileCommand.result;
    }

    // Update error state from any failed command
    _error = _getProfileCommand.error ?? 
             _updateProfileCommand.error ?? 
             _uploadProfilePictureCommand.error ?? 
             _uploadCVCommand.error;

    notifyListeners();
  }

  // Getters for UI state
  Profile? get currentProfile => _currentProfile;
  AppError? get error => _error;

  // Command getters for UI
  GetProfileCommand get getProfileCommand => _getProfileCommand;
  UpdateProfileCommand get updateProfileCommand => _updateProfileCommand;
  UploadProfilePictureCommand get uploadProfilePictureCommand => _uploadProfilePictureCommand;
  UploadCVCommand get uploadCVCommand => _uploadCVCommand;

  // Computed properties for UI convenience
  bool get isLoading => 
    _getProfileCommand.isExecuting ||
    _updateProfileCommand.isExecuting ||
    _uploadProfilePictureCommand.isExecuting ||
    _uploadCVCommand.isExecuting;

  bool get hasProfile => _currentProfile != null;

  List<String> get missingRequiredFields {
    if (_currentProfile == null) return ['Email', 'First Name', 'Last Name', 'Food Preferences'];

    final missing = <String>[];
    if (_currentProfile!.firstName.isEmpty) missing.add('First Name');
    if (_currentProfile!.lastName.isEmpty) missing.add('Last Name');
    if (_currentProfile!.foodPreferences?.isEmpty ?? true) missing.add('Food Preferences');

    return missing;
  }

  bool get isProfileComplete => missingRequiredFields.isEmpty;

  // Public methods for UI interactions
  Future<void> loadProfile() async {
    await _getProfileCommand.execute();
  }

  Future<bool> updateProfile(Profile profile) async {
    final result = await _updateProfileCommand.updateProfile(profile);
    
    if (result) {
      // Fire profile updated event
      AppEvents.fire(ProfileUpdatedEvent(profile));
      return true;
    }
    
    return false;
  }

  Future<bool> uploadProfilePicture(File file) async {
    final result = await _uploadProfilePictureCommand.uploadProfilePicture(file);
    
    if (result && _uploadProfilePictureCommand.uploadResult != null) {
      // Fire profile picture uploaded event
      AppEvents.fire(ProfilePictureUploadedEvent(_uploadProfilePictureCommand.uploadResult!));
      
      // Refresh profile to get updated picture URL
      await loadProfile();
      return true;
    }
    
    return false;
  }

  Future<bool> uploadCV(File file) async {
    final result = await _uploadCVCommand.uploadCV(file);
    
    if (result && _uploadCVCommand.uploadResult != null) {
      // Fire CV uploaded event
      AppEvents.fire(CVUploadedEvent(_uploadCVCommand.uploadResult!));
      
      // Refresh profile to get updated CV URL
      await loadProfile();
      return true;
    }
    
    return false;
  }

  Future<void> deleteProfilePicture() async {
    if (_currentProfile == null) return;

    final updatedProfile = _currentProfile!.copyWith(profilePictureUrl: '');
    final success = await updateProfile(updatedProfile);
    
    if (success && _currentProfile != null) {
      // Fire profile picture deleted event
      AppEvents.fire(ProfilePictureDeletedEvent(_currentProfile!.id));
    }
  }

  Future<void> deleteCV() async {
    if (_currentProfile == null) return;

    final updatedProfile = _currentProfile!.copyWith(cvUrl: '');
    final success = await updateProfile(updatedProfile);
    
    if (success && _currentProfile != null) {
      // Fire CV deleted event
      AppEvents.fire(CVDeletedEvent(_currentProfile!.id));
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Subscribe to authentication events to automatically load profile
  void _subscribeToAuthEvents() {
    _authSessionSubscription = AppEvents.on<AuthSessionChangedEvent>().listen((event) {
      _onUserAuthenticated();
    });
    
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((event) {
      _onUserSignedOut();
    });
  }

  /// Handle successful authentication by loading profile
  Future<void> _onUserAuthenticated() async {
    await loadProfile();
  }

  /// Handle sign out by clearing profile data
  void _onUserSignedOut() {
    _currentProfile = null;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _getProfileCommand.removeListener(_onCommandStateChanged);
    _updateProfileCommand.removeListener(_onCommandStateChanged);
    _uploadProfilePictureCommand.removeListener(_onCommandStateChanged);
    _uploadCVCommand.removeListener(_onCommandStateChanged);
    
    _getProfileCommand.dispose();
    _updateProfileCommand.dispose();
    _uploadProfilePictureCommand.dispose();
    _uploadCVCommand.dispose();
    
    // Cancel event subscriptions
    _authSessionSubscription?.cancel();
    _logoutSubscription?.cancel();
    
    super.dispose();
  }
}