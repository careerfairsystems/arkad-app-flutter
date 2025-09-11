import '../../../../shared/domain/result.dart';
import '../../../../shared/domain/use_case.dart';
import '../entities/student_session_application.dart';
import '../repositories/student_session_repository.dart';

/// Parameters for applying to a student session
class ApplyForSessionParams {
  final int companyId;
  final String motivationText;
  final String? programme;
  final String? linkedin;
  final String? masterTitle;
  final int? studyYear;
  final bool updateProfile;

  const ApplyForSessionParams({
    required this.companyId,
    required this.motivationText,
    this.programme,
    this.linkedin,
    this.masterTitle,
    this.studyYear,
    this.updateProfile = false,
  });
}

/// Use case for applying to a student session
class ApplyForSessionUseCase
    extends UseCase<StudentSessionApplication, ApplyForSessionParams> {
  final StudentSessionRepository _repository;

  ApplyForSessionUseCase(this._repository);

  @override
  Future<Result<StudentSessionApplication>> call(ApplyForSessionParams params) {
    return _repository.applyForSession(
      companyId: params.companyId,
      motivationText: params.motivationText,
      programme: params.programme,
      linkedin: params.linkedin,
      masterTitle: params.masterTitle,
      studyYear: params.studyYear,
      updateProfile: params.updateProfile,
    );
  }
}
