import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/book_timeslot_use_case.dart';

/// Command for booking a timeslot with defensive pattern implementation and conflict resolution
class BookTimeslotCommand
    extends ParameterizedCommand<BookTimeslotParams, String> {
  BookTimeslotCommand(this._bookTimeslotUseCase);

  final BookTimeslotUseCase _bookTimeslotUseCase;

  // Message state for this command
  bool _showSuccessMessage = false;
  String? _successMessage;
  bool _showErrorMessage = false;
  String? _errorMessage;

  // Message getters
  bool get showSuccessMessage => _showSuccessMessage;
  String? get successMessage => _successMessage;
  bool get showErrorMessage => _showErrorMessage;
  String? get errorMessage => _errorMessage;

  // Message management methods
  void _setSuccessMessage(String message) {
    _showSuccessMessage = true;
    _successMessage = message;
    notifyListeners();
  }

  void _setErrorMessage(String message) {
    _showErrorMessage = true;
    _errorMessage = message;
    notifyListeners();
  }

  void clearSuccessMessage() {
    _showSuccessMessage = false;
    _successMessage = null;
    notifyListeners();
  }

  void clearErrorMessage() {
    _showErrorMessage = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearAllMessages({bool notify = true}) {
    _showSuccessMessage = false;
    _successMessage = null;
    _showErrorMessage = false;
    _errorMessage = null;
    if (notify) {
      notifyListeners();
    }
  }

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
    clearAllMessages(); // Clear any previous messages
    setExecuting(true);

    try {
      // Validate booking parameters
      final validationError = _validateBookingParams(params);
      if (validationError != null) {
        setError(validationError);
        _setErrorMessage(validationError.userMessage);
        return;
      }

      // Execute single booking attempt - conflict resolution handled at ViewModel level
      final result = await _bookTimeslotUseCase.call(params);

      result.when(
        success: (successMessage) {
          setResult(successMessage);
          _setSuccessMessage('Timeslot booked successfully!');
        },
        failure: (error) {
          setError(error);
          _setErrorMessage(error.userMessage);
        },
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      const error = StudentSessionApplicationError(
        'Failed to book timeslot',
        details: 'Unable to book timeslot. Please try again.',
      );
      setError(error);
      _setErrorMessage(error.userMessage);
    } finally {
      setExecuting(false);
    }
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

  // Timeline error check removed - booking controlled by userStatus and server data


  /// Reset command state and clear any errors and messages
  @override
  void reset({bool notify = true}) {
    clearAllMessages(notify: notify);
    super.reset(notify: notify);
  }
}
