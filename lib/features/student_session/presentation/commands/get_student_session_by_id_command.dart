import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/use_cases/get_student_session_by_id_use_case.dart';

/// Command for getting a specific student session by company ID
class GetStudentSessionByIdCommand
    extends ParameterizedCommand<int, StudentSession> {
  GetStudentSessionByIdCommand(this._getStudentSessionByIdUseCase);

  final GetStudentSessionByIdUseCase _getStudentSessionByIdUseCase;

  /// Get student session by company ID
  Future<void> getSessionById(int companyId) async {
    return executeWithParams(companyId);
  }

  @override
  Future<void> executeWithParams(int companyId) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      final result = await _getStudentSessionByIdUseCase.call(companyId);
      
      result.when(
        success: (session) {
          if (session != null) {
            setResult(session);
          } else {
            setError(StudentSessionApplicationError(
              'Student session not found for company $companyId',
            ));
          }
        },
        failure: (error) => setError(error),
      );
    } catch (e) {
      setError(StudentSessionApplicationError(
        'Failed to get student session',
        details: e.toString(),
      ));
    } finally {
      setExecuting(false);
    }
  }
}