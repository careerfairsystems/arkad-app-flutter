import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/use_cases/apply_for_session_use_case.dart';

/// Parameters for applying to a student session
class ApplyForSessionParams {
  const ApplyForSessionParams({
    required this.companyId,
    required this.motivationText,
    this.programme,
    this.linkedin,
    this.masterTitle,
    this.studyYear,
  });

  final int companyId;
  final String motivationText;
  final String? programme;
  final String? linkedin;
  final String? masterTitle;
  final int? studyYear;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ApplyForSessionParams &&
        other.companyId == companyId &&
        other.motivationText == motivationText &&
        other.programme == programme &&
        other.linkedin == linkedin &&
        other.masterTitle == masterTitle &&
        other.studyYear == studyYear;
  }

  @override
  int get hashCode => Object.hash(
    companyId,
    motivationText,
    programme,
    linkedin,
    masterTitle,
    studyYear,
  );

  @override
  String toString() => 'ApplyForSessionParams(companyId: $companyId)';
}

/// Command for applying to a student session with defensive pattern implementation
class ApplyForSessionCommand
    extends ParameterizedCommand<ApplyForSessionParams, String> {
  ApplyForSessionCommand(this._applyForSessionUseCase);

  final ApplyForSessionUseCase _applyForSessionUseCase;

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

  /// Apply for a student session with comprehensive validation and error handling
  Future<void> applyForSession({
    required int companyId,
    required String motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
  }) async {
    final params = ApplyForSessionParams(
      companyId: companyId,
      motivationText: motivationText,
      programme: programme,
      linkedin: linkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
    );

    return executeWithParams(params);
  }

  @override
  Future<void> executeWithParams(ApplyForSessionParams params) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
      // Validate application parameters
      final validationError = _validateApplicationParams(params);
      if (validationError != null) {
        setError(validationError);
        return;
      }

      // Execute the use case
      final result = await _applyForSessionUseCase.call(
        StudentSessionApplicationParams(
          companyId: params.companyId,
          motivationText: params.motivationText,
          programme: params.programme,
          linkedin: params.linkedin,
          masterTitle: params.masterTitle,
          studyYear: params.studyYear,
        ),
      );

      result.when(
        success: (successMessage) {
          setResult(successMessage);
          _setSuccessMessage(successMessage);
        },
        failure: (error) {
          setError(error);
          _setErrorMessage(error.userMessage);
        },
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      const errorMessage = 'Failed to submit application';
      setError(
        const StudentSessionApplicationError(
          errorMessage,
          details: 'An unexpected error occurred. Please try again.',
        ),
      );
      _setErrorMessage(errorMessage);
    } finally {
      setExecuting(false);
    }
  }

  /// Validates application parameters before submission
  StudentSessionApplicationError? _validateApplicationParams(
    ApplyForSessionParams params,
  ) {
    // Company ID validation
    if (params.companyId <= 0) {
      return const StudentSessionApplicationError(
        'Invalid company selection. Please select a valid company.',
      );
    }

    // Motivation text validation (aligned with UI word-based validation)
    if (params.motivationText.trim().isEmpty) {
      return const StudentSessionApplicationError(
        'Motivation text is required. Please explain why you want to meet this company.',
      );
    }

    // Use word-based validation to match UI (≤300 words)
    final words = params.motivationText.trim().split(RegExp(r'\s+'));
    if (words.length > 300) {
      return StudentSessionApplicationError(
        'Motivation text must be 300 words or less. Currently ${words.length} words.',
      );
    }

    // Study year validation (if provided)
    if (params.studyYear != null) {
      if (params.studyYear! < 1 || params.studyYear! > 10) {
        return const StudentSessionApplicationError(
          'Please select a valid study year (1-10).',
        );
      }
    }

    // LinkedIn validation (if provided)
    if (params.linkedin != null && params.linkedin!.isNotEmpty) {
      if (!ValidationService.isValidLinkedInUrl(params.linkedin!)) {
        return const StudentSessionApplicationError(
          'Please provide a valid LinkedIn URL (e.g., https://www.linkedin.com/in/username).',
        );
      }
    }

    return null;
  }

  /// Reset command state and clear any errors and messages
  @override
  void reset({bool notify = true}) {
    clearAllMessages(notify: false);
    super.reset(notify: notify);
  }
}
