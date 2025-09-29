import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/commands/base_command.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/use_cases/get_timeslots_use_case.dart';

/// Command for getting available timeslots for a company with defensive pattern
class GetTimeslotsCommand extends ParameterizedCommand<int, List<Timeslot>> {
  GetTimeslotsCommand(this._getTimeslotsUseCase);

  final GetTimeslotsUseCase _getTimeslotsUseCase;

  /// Load timeslots for a specific company with optional force refresh
  Future<void> loadTimeslots(int companyId, {bool forceRefresh = false}) async {
    return executeWithParams(companyId);
  }

  @override
  Future<void> executeWithParams(int companyId) async {
    if (isExecuting) return;

    clearError();
    setExecuting(true);

    try {
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
      final result = await _getTimeslotsUseCase.call(companyId);

      result.when(
        success: (timeslots) => setResult(timeslots),
        failure: (error) => setError(error),
      );
    } catch (e) {
      // Convert unexpected exceptions to user-friendly errors
      setError(
        const StudentSessionApplicationError(
          'Failed to load available timeslots',
          details: 'Unable to load timeslots. Please try again.',
        ),
      );
    } finally {
      setExecuting(false);
    }
  }

  /// Check if timeslots were loaded successfully
  bool get hasTimeslots => result != null && result!.isNotEmpty;

  /// Get timeslots count
  int get timeslotCount => result?.length ?? 0;

  /// Get available timeslots (not booked)
  List<Timeslot> get availableTimeslots =>
      result?.where((slot) => !slot.isBooked).toList() ?? [];

  /// Get booked timeslots
  List<Timeslot> get bookedTimeslots =>
      result?.where((slot) => slot.isBooked).toList() ?? [];

  /// Get timeslots grouped by date
  Map<DateTime, List<Timeslot>> get timeslotsByDate {
    if (result == null) return {};

    final Map<DateTime, List<Timeslot>> grouped = {};
    for (final slot in result!) {
      final date = DateTime(
        slot.startTime.year,
        slot.startTime.month,
        slot.startTime.day,
      );
      if (!grouped.containsKey(date)) {
        grouped[date] = [];
      }
      grouped[date]!.add(slot);
    }

    // Sort timeslots within each date
    for (final daySlots in grouped.values) {
      daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return grouped;
  }

  // Status description removed - command state accessible via isExecuting, hasError, result

  /// Reset command state and clear any errors
  @override
  void reset({bool notify = true}) {
    super.reset(notify: notify);
  }
}
