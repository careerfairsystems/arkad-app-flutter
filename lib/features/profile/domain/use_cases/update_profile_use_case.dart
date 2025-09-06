import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../../../../shared/errors/app_error.dart';
import '../entities/profile.dart';
import '../repositories/profile_repository.dart';

/// Use case for updating user profile
class UpdateProfileUseCase extends UseCase<Profile, UpdateProfileParams> {
  const UpdateProfileUseCase(this._repository);

  final ProfileRepository _repository;

  @override
  Future<Result<Profile>> call(UpdateProfileParams params) async {
    // Validate profile data
    final validation = _repository.validateProfile(params.profile);
    if (validation.isFailure) {
      return Result.failure(validation.errorOrNull!);
    }

    // Validate LinkedIn URL format if provided
    if (params.profile.linkedin != null &&
        params.profile.linkedin!.isNotEmpty) {
      if (!_isValidLinkedInUrl(params.profile.linkedin!)) {
        return Result.failure(
          const ValidationError("Please enter a valid LinkedIn profile URL"),
        );
      }
    }

    // Update profile
    return await _repository.updateProfile(params.profile);
  }

  bool _isValidLinkedInUrl(String url) {
    // Accept LinkedIn URLs in various formats
    final patterns = [
      r'^https://www\.linkedin\.com/in/[\w\-]+/?$',
      r'^https://linkedin\.com/in/[\w\-]+/?$',
      r'^www\.linkedin\.com/in/[\w\-]+/?$',
      r'^linkedin\.com/in/[\w\-]+/?$',
    ];

    return patterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url),
    );
  }
}

/// Parameters for update profile use case
class UpdateProfileParams {
  const UpdateProfileParams({required this.profile});

  final Profile profile;
}
