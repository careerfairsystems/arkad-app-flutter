import 'dart:io';

import '../../../../shared/domain/result.dart';
import '../entities/file_upload_result.dart';
import '../entities/profile.dart';

/// Repository interface for profile operations
abstract class ProfileRepository {
  /// Get current user profile
  Future<Result<Profile>> getCurrentProfile();

  /// Update user profile information
  Future<Result<Profile>> updateProfile(Profile profile);

  /// Upload profile picture
  Future<Result<FileUploadResult>> uploadProfilePicture(File imageFile);

  /// Upload CV document  
  Future<Result<FileUploadResult>> uploadCV(File cvFile);

  /// Delete profile picture
  Future<Result<void>> deleteProfilePicture();

  /// Delete CV document
  Future<Result<void>> deleteCV();

  /// Get available study programmes
  List<String> getAvailableProgrammeLabels();

  /// Validate profile data before update
  Result<void> validateProfile(Profile profile);

  /// Get profile completion suggestions
  List<String> getCompletionSuggestions(Profile profile);
}