import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/use_cases/switch_timeslot_use_case.dart';

/// Command for switching timeslots atomically with defensive pattern implementation
class SwitchTimeslotCommand
    extends ParameterizedCommand<SwitchTimeslotParams, String> {
  SwitchTimeslotCommand(this._switchTimeslotUseCase);

  final SwitchTimeslotUseCase _switchTimeslotUseCase;

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

  /// Check if the last error was a timeslot conflict
  bool get isTimeslotConflict => error is StudentSessionBookingConflictError;

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

  /// Switch timeslots atomically with comprehensive validation
  Future<void> switchTimeslot(int fromTimeslotId, int newTimeslotId) async {
    return executeWithParams(
      SwitchTimeslotParams(
        fromTimeslotId: fromTimeslotId,
        newTimeslotId: newTimeslotId,
      ),
    );
  }

  @override
  Future<void> executeWithParams(SwitchTimeslotParams params) async {
    if (isExecuting) return;

    clearError();
    clearAllMessages(); // Clear any previous messages
    setExecuting(true);

    try {
      // Execute the use case
      final result = await _switchTimeslotUseCase.call(params);

      result.when(
        success: (successMessage) {
          setResult(successMessage);
          _setSuccessMessage('Timeslot switched successfully!');
        },
        failure: (error) {
          setError(error);
          _setErrorMessage(error.userMessage);
        },
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      const error = StudentSessionApplicationError(
        'Failed to switch timeslot',
        details:
            'Unable to switch timeslots. Please try again or contact support.',
      );
      setError(error);
      _setErrorMessage(error.userMessage);
    } finally {
      setExecuting(false);
    }
  }

  /// Reset command state and clear any errors and messages
  @override
  void reset({bool notify = true}) {
    clearAllMessages(notify: notify);
    super.reset(notify: notify);
  }
}
