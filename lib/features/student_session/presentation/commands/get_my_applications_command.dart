import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/use_cases/get_my_applications_use_case.dart';

/// Command for getting user's student session applications with defensive pattern
class GetMyApplicationsCommand
    extends Command<List<StudentSessionApplication>> {
  GetMyApplicationsCommand(this._getMyApplicationsUseCase);

  final GetMyApplicationsUseCase _getMyApplicationsUseCase;

  /// Load user's applications with optional force refresh
  Future<void> loadMyApplications({bool forceRefresh = false}) async {
    return execute();
  }

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      // Execute the use case
      final result = await _getMyApplicationsUseCase.call();

      result.when(
        success: (applications) => setResult(applications),
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        StudentSessionApplicationError(
          'Failed to load your applications',
          details: e.toString(),
        ),
      );
    } finally {
      setExecuting(false);
    }
  }

  /// Check if applications were loaded successfully
  bool get hasApplications => result != null && result!.isNotEmpty;

  /// Get applications count
  int get applicationCount => result?.length ?? 0;

  /// Get applications by status
  List<StudentSessionApplication> getApplicationsByStatus(
    ApplicationStatus status,
  ) {
    return result?.where((app) => app.status == status).toList() ?? [];
  }

  /// Get pending applications
  List<StudentSessionApplication> get pendingApplications =>
      getApplicationsByStatus(ApplicationStatus.pending);

  /// Get accepted applications
  List<StudentSessionApplication> get acceptedApplications =>
      getApplicationsByStatus(ApplicationStatus.accepted);

  /// Get rejected applications
  List<StudentSessionApplication> get rejectedApplications =>
      getApplicationsByStatus(ApplicationStatus.rejected);

  /// Get a user-friendly description of the current state
  String get statusDescription {
    if (isExecuting) return 'Loading your applications...';
    if (isCompleted && result != null) {
      return 'Loaded ${result!.length} applications';
    }
    if (hasError) {
      return error?.userMessage ?? 'Failed to load applications';
    }
    return 'Ready to load applications';
  }

  /// Reset command state and clear any errors
  @override
  void reset({bool notify = true}) {
    super.reset(notify: notify);
  }
}
