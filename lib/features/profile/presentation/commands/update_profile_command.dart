import '../../../../shared/presentation/commands/result_command.dart';
import '../../domain/entities/profile.dart';
import '../../domain/use_cases/update_profile_use_case.dart';

/// Command for updating user profile
class UpdateProfileCommand extends ParameterizedResultCommand<UpdateProfileParams, Profile> {
  final UpdateProfileUseCase _useCase;

  UpdateProfileCommand(this._useCase);

  @override
  Future<bool> executeForResultWithParams(UpdateProfileParams params) async {
    if (isExecuting) return false;

    setExecuting(true);

    final result = await _useCase(params);
    
    final success = result.when(
      success: (updatedProfile) {
        setResult(updatedProfile);
        return true;
      },
      failure: (error) {
        setError(error);
        return false;
      },
    );

    setExecuting(false);
    return success;
  }

  /// Convenience method for executing with profile
  Future<bool> updateProfile(Profile profile) async {
    return await executeForResultWithParams(UpdateProfileParams(profile: profile));
  }
}