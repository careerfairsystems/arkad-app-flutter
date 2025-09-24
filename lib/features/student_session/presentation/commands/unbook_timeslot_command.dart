import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../domain/use_cases/unbook_timeslot_use_case.dart';

/// Command for unbooking a timeslot with defensive pattern implementation
class UnbookTimeslotCommand extends ParameterizedCommand<int, String> {
  UnbookTimeslotCommand(this._unbookTimeslotUseCase);

  final UnbookTimeslotUseCase _unbookTimeslotUseCase;
  
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
  
  void clearAllMessages() {
    _showSuccessMessage = false;
    _successMessage = null;
    _showErrorMessage = false;
    _errorMessage = null;
    notifyListeners();
  }

  /// Unbook a timeslot with comprehensive validation
  Future<void> unbookTimeslot(int companyId) async {
    return executeWithParams(companyId);
  }

  @override
  Future<void> executeWithParams(int companyId) async {
    if (isExecuting) return;

    clearError();
    clearAllMessages(); // Clear any previous messages
    setExecuting(true);

    try {
      // Pre-execution validation: Check booking timeline constraints
      try {
        TimelineValidationService.validateBookingAllowed();
      } on StudentSessionTimelineError catch (e) {
        setError(e);
        _setErrorMessage(e.userMessage);
        return;
      }

      // Validate company ID
      if (companyId <= 0) {
        const error = StudentSessionApplicationError(
          'Invalid company selection. Please select a valid company.',
        );
        setError(error);
        _setErrorMessage(error.userMessage);
        return;
      }

      // Execute the use case
      final result = await _unbookTimeslotUseCase.call(companyId);

      result.when(
        success: (successMessage) {
          setResult(successMessage);
          _setSuccessMessage('Booking cancelled successfully!');
        },
        failure: (error) {
          setError(error);
          _setErrorMessage(error.userMessage);
        },
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      final error = StudentSessionApplicationError(
        'Failed to unbook timeslot',
        details: e.toString(),
      );
      setError(error);
      _setErrorMessage(error.userMessage);
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

  /// Reset command state and clear any errors and messages
  @override
  void reset({bool notify = true}) {
    clearAllMessages();
    super.reset(notify: notify);
  }
}
