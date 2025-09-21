import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../domain/use_cases/book_timeslot_use_case.dart';

/// Command for booking a timeslot with defensive pattern implementation and conflict resolution
class BookTimeslotCommand
    extends ParameterizedCommand<BookTimeslotParams, String> {
  BookTimeslotCommand(this._bookTimeslotUseCase);

  final BookTimeslotUseCase _bookTimeslotUseCase;

  /// Book a timeslot with comprehensive validation and conflict resolution
  Future<void> bookTimeslot({
    required int companyId,
    required int timeslotId,
  }) async {
    final params = BookTimeslotParams(
      companyId: companyId,
      timeslotId: timeslotId,
    );

    return executeWithParams(params);
  }

  @override
  Future<void> executeWithParams(BookTimeslotParams params) async {
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

      // Validate booking parameters
      final validationError = _validateBookingParams(params);
      if (validationError != null) {
        setError(validationError);
        return;
      }

      // Execute the use case with retry logic for conflicts
      final result = await _executeWithRetry(params);

      result.when(
        success: (successMessage) => setResult(successMessage),
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        StudentSessionApplicationError(
          'Failed to book timeslot',
          details: e.toString(),
        ),
      );
    } finally {
      setExecuting(false);
    }
  }

  /// Execute booking with retry logic for handling conflicts
  Future<Result<String>> _executeWithRetry(
    BookTimeslotParams params, {
    int retryCount = 0,
  }) async {
    const maxRetries = 2;

    final result = await _bookTimeslotUseCase.call(params);

    // Check if we got a booking conflict and should retry
    if (retryCount < maxRetries) {
      return result.when(
        success: (value) => result,
        failure: (error) async {
          if (error is StudentSessionBookingConflictError) {
            // Wait a short time before retrying
            await Future.delayed(const Duration(milliseconds: 500));
            return _executeWithRetry(params, retryCount: retryCount + 1);
          }
          return result;
        },
      );
    }

    return result;
  }

  /// Validates booking parameters before execution
  StudentSessionApplicationError? _validateBookingParams(
    BookTimeslotParams params,
  ) {
    // Company ID validation
    if (params.companyId <= 0) {
      return const StudentSessionApplicationError(
        'Invalid company selection. Please select a valid company.',
      );
    }

    // Timeslot ID validation
    if (params.timeslotId <= 0) {
      return const StudentSessionApplicationError(
        'Invalid timeslot selection. Please select a valid timeslot.',
      );
    }

    return null;
  }

  /// Check if the last error was a booking conflict
  bool get isBookingConflict => error is StudentSessionBookingConflictError;

  /// Check if the last error was due to capacity being full
  bool get isCapacityFull => error is StudentSessionCapacityError;

  /// Check if the last error was a timeline error
  bool get isTimelineError => error is StudentSessionTimelineError;

  /// Get a user-friendly description of the current state
  String get statusDescription {
    if (isExecuting) return 'Booking timeslot...';
    if (isCompleted && result != null) return 'Timeslot booked successfully';
    if (hasError) {
      if (isBookingConflict) {
        return 'This timeslot was just taken by someone else';
      }
      if (isCapacityFull) return 'This session is now full';
      if (isTimelineError) return 'Booking is not currently available';
      return error?.userMessage ?? 'Failed to book timeslot';
    }
    return 'Ready to book';
  }

  /// Reset command state and clear any errors
  @override
  void reset({bool notify = true}) {
    super.reset(notify: notify);
  }
}
