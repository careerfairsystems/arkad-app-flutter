import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/use_cases/get_my_applications_with_booking_state_use_case.dart';

/// Command for getting user's student session applications with real booking state
/// This command provides accurate booking information by checking timeslot status
class GetMyApplicationsWithBookingStateCommand
    extends Command<List<StudentSessionApplicationWithBookingState>> {
  GetMyApplicationsWithBookingStateCommand(this._getMyApplicationsWithBookingStateUseCase);

  final GetMyApplicationsWithBookingStateUseCase _getMyApplicationsWithBookingStateUseCase;

  /// Load user's applications with booking state
  Future<void> loadMyApplicationsWithBookingState({bool forceRefresh = false}) async {
    return execute();
  }

  @override
  Future<void> execute() async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      // Execute the use case
      final result = await _getMyApplicationsWithBookingStateUseCase.call();

      result.when(
        success: (applications) => setResult(applications),
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        StudentSessionApplicationError(
          'Failed to load your applications with booking state',
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

  /// Get applications by status with their booking state
  List<StudentSessionApplicationWithBookingState> getApplicationsByStatus(
    ApplicationStatus status,
  ) {
    return result?.where((app) => app.application.status == status).toList() ?? [];
  }

  /// Get pending applications
  List<StudentSessionApplicationWithBookingState> get pendingApplications =>
      getApplicationsByStatus(ApplicationStatus.pending);

  /// Get accepted applications
  List<StudentSessionApplicationWithBookingState> get acceptedApplications =>
      getApplicationsByStatus(ApplicationStatus.accepted);

  /// Get rejected applications
  List<StudentSessionApplicationWithBookingState> get rejectedApplications =>
      getApplicationsByStatus(ApplicationStatus.rejected);

  /// Get accepted applications that can be booked
  List<StudentSessionApplicationWithBookingState> get bookableApplications =>
      acceptedApplications.where((app) => app.canBook).toList();

  /// Get accepted applications that are currently booked
  List<StudentSessionApplicationWithBookingState> get bookedApplications =>
      acceptedApplications.where((app) => app.hasBooking).toList();

  /// Get accepted applications that can cancel their booking
  List<StudentSessionApplicationWithBookingState> get cancellableApplications =>
      acceptedApplications.where((app) => app.canCancelBooking).toList();

  /// Get a user-friendly description of the current state
  String get statusDescription {
    if (isExecuting) return 'Loading your applications...';
    if (isCompleted && result != null) {
      final totalApps = result!.length;
      final bookedCount = bookedApplications.length;
      return 'Loaded $totalApps applications ($bookedCount with bookings)';
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