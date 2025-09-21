import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../domain/use_cases/unbook_timeslot_use_case.dart';

/// Command for unbooking a timeslot with defensive pattern implementation
class UnbookTimeslotCommand extends ParameterizedCommand<int, String> {
  UnbookTimeslotCommand(this._unbookTimeslotUseCase);

  final UnbookTimeslotUseCase _unbookTimeslotUseCase;

  /// Unbook a timeslot with comprehensive validation
  Future<void> unbookTimeslot(int companyId) async {
    return executeWithParams(companyId);
  }

  @override
  Future<void> executeWithParams(int companyId) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      // Pre-execution validation: Check booking timeline constraints
      try {
        TimelineValidationService.validateBookingAllowed();
      } on StudentSessionTimelineError catch (e) {
        setError(e);
        return;
      }

      // Validate company ID
      if (companyId <= 0) {
        setError(
          const StudentSessionApplicationError(
            'Invalid company selection. Please select a valid company.',
          ),
        );
        return;
      }

      // Execute the use case
      final result = await _unbookTimeslotUseCase.call(companyId);

      result.when(
        success: (successMessage) => setResult(successMessage),
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        StudentSessionApplicationError(
          'Failed to unbook timeslot',
          details: e.toString(),
        ),
      );
    } finally {
      setExecuting(false);
    }
  }

  /// Check if the last error was a timeline error
  bool get isTimelineError => error is StudentSessionTimelineError;

  /// Get a user-friendly description of the current state
  String get statusDescription {
    if (isExecuting) return 'Unbooking timeslot...';
    if (isCompleted && result != null) return 'Timeslot unbooked successfully';
    if (hasError) {
      if (isTimelineError) return 'Unbooking is not currently available';
      return error?.userMessage ?? 'Failed to unbook timeslot';
    }
    return 'Ready to unbook';
  }

  /// Reset command state and clear any errors
  @override
  void reset({bool notify = true}) {
    super.reset(notify: notify);
  }
}
