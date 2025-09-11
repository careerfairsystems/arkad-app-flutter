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

  // Commands for UI operations 
  late final GetProfileCommand _getProfileCommand;
  late final UpdateProfileCommand _updateProfileCommand;
  late final UploadProfilePictureCommand _uploadProfilePictureCommand;
  late final UploadCVCommand _uploadCVCommand;

  // Current profile state 
  Profile? _currentProfile;

  ProfileViewModel({
    required GetCurrentProfileUseCase getCurrentProfileUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required UploadProfilePictureUseCase uploadProfilePictureUseCase,
    required UploadCVUseCase uploadCVUseCase,
  }) {
    _initializeCommands(
      getCurrentProfileUseCase,
      updateProfileUseCase,
      uploadProfilePictureUseCase,
      uploadCVUseCase,
    );
    _subscribeToAuthEvents();
    // Profile will be loaded when explicitly requested or after auth success
  }

  void _initializeCommands(
    GetCurrentProfileUseCase getCurrentProfileUseCase,
    UpdateProfileUseCase updateProfileUseCase,
    UploadProfilePictureUseCase uploadProfilePictureUseCase,
    UploadCVUseCase uploadCVUseCase,
  ) {
    _getProfileCommand = GetProfileCommand(getCurrentProfileUseCase);
    _updateProfileCommand = UpdateProfileCommand(updateProfileUseCase);
    _uploadProfilePictureCommand = UploadProfilePictureCommand(
      uploadProfilePictureUseCase,
    );
    _uploadCVCommand = UploadCVCommand(uploadCVUseCase);

    // Command coordination 
    _getProfileCommand.addListener(_onGetProfileCommandChanged);
    _updateProfileCommand.addListener(_onUpdateProfileCommandChanged);
    _uploadProfilePictureCommand.addListener(
      _onUploadProfilePictureCommandChanged,
    );
    _uploadCVCommand.addListener(_onUploadCVCommandChanged);
  }

  // Layer 2: VIEWMODELS 
  void _onGetProfileCommandChanged() {
    if (_getProfileCommand.isCompleted && _getProfileCommand.result != null) {
      _currentProfile = _getProfileCommand.result;
      // Fire profile loaded event
      _fireProfileEvent(ProfileLoadedEvent(_getProfileCommand.result!));
    }
    notifyListeners();
  }

  void _onUpdateProfileCommandChanged() {
    if (_updateProfileCommand.isCompleted &&
        _updateProfileCommand.result != null) {
      _currentProfile = _updateProfileCommand.result;
      // Fire profile updated event
      _fireProfileEvent(ProfileUpdatedEvent(_updateProfileCommand.result!));
    }
    notifyListeners();
  }

  void _onUploadProfilePictureCommandChanged() {
    if (_uploadProfilePictureCommand.isCompleted &&
        _uploadProfilePictureCommand.uploadResult != null) {
      // Fire profile picture uploaded event
      _fireProfileEvent(
        ProfilePictureUploadedEvent(_uploadProfilePictureCommand.uploadResult!),
      );
      // Refresh profile to get updated picture URL
      loadProfile();
    }
    notifyListeners();
  }

  void _onUploadCVCommandChanged() {
    if (_uploadCVCommand.isCompleted && _uploadCVCommand.uploadResult != null) {
      // Fire CV uploaded event
      _fireProfileEvent(CVUploadedEvent(_uploadCVCommand.uploadResult!));
      // Refresh profile to get updated CV URL
      loadProfile();
    }
    notifyListeners();
  }

  // Getters for UI state
  Profile? get currentProfile => _currentProfile;

  // Aggregate error from all commands
  AppError? get error =>
      _getProfileCommand.error ??
      _updateProfileCommand.error ??
      _uploadProfilePictureCommand.error ??
      _uploadCVCommand.error;

  // Command getters for UI
  GetProfileCommand get getProfileCommand => _getProfileCommand;
  UpdateProfileCommand get updateProfileCommand => _updateProfileCommand;
  UploadProfilePictureCommand get uploadProfilePictureCommand =>
      _uploadProfilePictureCommand;
  UploadCVCommand get uploadCVCommand => _uploadCVCommand;

  // Computed properties for UI convenience
  bool get isLoading =>
      _getProfileCommand.isExecuting ||
      _updateProfileCommand.isExecuting ||
      _uploadProfilePictureCommand.isExecuting ||
      _uploadCVCommand.isExecuting;

  bool get hasProfile => _currentProfile != null;

  List<String> get missingRequiredFields {
    if (_currentProfile == null) {
      return ['Email', 'First Name', 'Last Name', 'Food Preferences'];
    }

    final missing = <String>[];
    if (_currentProfile!.firstName.isEmpty) missing.add('First Name');
    if (_currentProfile!.lastName.isEmpty) missing.add('Last Name');
    if (_currentProfile!.foodPreferences?.isEmpty ?? true) {
      missing.add('Food Preferences');
    }

    return missing;
  }

  bool get isProfileComplete => missingRequiredFields.isEmpty;

  Future<void> loadProfile() async {
    await _getProfileCommand.execute();
  }

  Future<bool> updateProfile(Profile profile) async {
    // Reset get command so update result can take priority
    _getProfileCommand.reset();
    return await _updateProfileCommand.updateProfile(profile);
  }

  Future<bool> uploadProfilePicture(File file) async {
    return await _uploadProfilePictureCommand.uploadProfilePicture(file);
  }

  Future<bool> uploadCV(File file) async {
    return await _uploadCVCommand.uploadCV(file);
  }

  Future<void> deleteProfilePicture() async {
    if (_currentProfile == null) return;

    final updatedProfile = _currentProfile!.copyWith(profilePictureUrl: '');
    final success = await updateProfile(updatedProfile);

    if (success && _currentProfile != null) {
      // Fire profile picture deleted event
      _fireProfileEvent(ProfilePictureDeletedEvent(_currentProfile!.id));
    }
  }

  Future<void> deleteCV() async {
    if (_currentProfile == null) return;

    final updatedProfile = _currentProfile!.copyWith(cvUrl: '');
    final success = await updateProfile(updatedProfile);

    if (success && _currentProfile != null) {
      // Fire CV deleted event
      _fireProfileEvent(CVDeletedEvent(_currentProfile!.id));
    }
  }

  Future<void> refreshProfile() async {
    await loadProfile();
  }

  void clearError() {
    // Clear all command errors
    _getProfileCommand.clearError();
    _updateProfileCommand.clearError();
    _uploadProfilePictureCommand.clearError();
    _uploadCVCommand.clearError();
    notifyListeners();
  }

  /// Fire profile events - only from ViewModels
  void _fireProfileEvent(Object event) => AppEvents.fire(event);

  /// Subscribe to authentication events to automatically load profile
  void _subscribeToAuthEvents() {
    _authSessionSubscription = AppEvents.on<AuthSessionChangedEvent>().listen((
      event,
    ) {
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
    // Clear all command states
    _getProfileCommand.reset();
    _updateProfileCommand.reset();
    _uploadProfilePictureCommand.reset();
    _uploadCVCommand.reset();
    notifyListeners();
  }

  @override
  void dispose() {
    // Remove command listeners
    _getProfileCommand.removeListener(_onGetProfileCommandChanged);
    _updateProfileCommand.removeListener(_onUpdateProfileCommandChanged);
    _uploadProfilePictureCommand.removeListener(
      _onUploadProfilePictureCommandChanged,
    );
    _uploadCVCommand.removeListener(_onUploadCVCommandChanged);

    // Dispose commands
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
