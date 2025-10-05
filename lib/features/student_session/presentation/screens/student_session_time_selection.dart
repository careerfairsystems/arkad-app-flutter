import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/timeslot.dart';
import '../../domain/services/timeline_validation_service.dart';
import '../view_models/student_session_view_model.dart';

class StudentSessionTimeSelectionScreen extends StatefulWidget {
  final String id;
  final bool isBookingMode;

  const StudentSessionTimeSelectionScreen({
    required this.id,
    this.isBookingMode = false,
    super.key,
  });

  @override
  State<StudentSessionTimeSelectionScreen> createState() =>
      _StudentSessionTimeSelection();
}

class _StudentSessionTimeSelection
    extends State<StudentSessionTimeSelectionScreen> {
  int? _selectedTimeslotId;
  bool _hasLoadedData = false;

  // Store ViewModel reference to prevent unsafe ancestor lookups during disposal
  StudentSessionViewModel? _viewModel;

  // Message handling state to prevent duplicates and setState during build
  bool _hasHandledBookingSuccess = false;
  bool _hasHandledBookingError = false;
  bool _hasHandledUnbookingSuccess = false;
  bool _hasHandledUnbookingError = false;

  /// Get selected timeslot from current timeslots list using ID
  Timeslot? _getSelectedTimeslot(List<Timeslot> timeslots) {
    if (_selectedTimeslotId == null) return null;
    return timeslots
        .where((slot) => slot.id == _selectedTimeslotId)
        .firstOrNull;
  }

  /// Check if current selection is valid (exists, available, and timeline valid)
  bool _isSelectionValid(List<Timeslot> timeslots) {
    final selectedSlot = _getSelectedTimeslot(timeslots);
    if (selectedSlot == null) return false;

    const timelineService = TimelineValidationService.instance;
    final isTimelineValid = timelineService.isTimeslotBookingOpen(selectedSlot);

    return (selectedSlot.status.isAvailable ||
            selectedSlot.status.isBookedByCurrentUser) &&
        isTimelineValid;
  }

  @override
  void initState() {
    super.initState();

    // Set company context on next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = Provider.of<StudentSessionViewModel>(
          context,
          listen: false,
        );

        viewModel.bookTimeslotCommand.reset();
        viewModel.unbookTimeslotCommand.reset();

        final companyId = int.tryParse(widget.id);
        if (companyId != null) {
          viewModel.setSelectedCompany(companyId);
        } else {
          // Handle invalid company ID in route
          if (mounted && context.mounted) {
            context.pop();
          }
        }
      }
    });
  }

  @override
  void dispose() {
    // Essential cleanup to prevent memory leaks
    // Use cached reference to avoid unsafe ancestor lookup during disposal
    _viewModel?.setSelectedCompany(null);

    super.dispose();
  }

  /// Smart message handling with guards to prevent setState during build
  void _handleCommandMessages(StudentSessionViewModel viewModel) {
    final bookCommand = viewModel.bookTimeslotCommand;
    final unbookCommand = viewModel.unbookTimeslotCommand;

    // Handle booking success messages
    if (bookCommand.showSuccessMessage && !_hasHandledBookingSuccess) {
      _hasHandledBookingSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookCommand.successMessage ?? 'Timeslot booked successfully!',
              ),
              backgroundColor: ArkadColors.arkadGreen,
            ),
          );

          bookCommand.clearSuccessMessage();

          // Navigate back after success
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted &&
                context.mounted &&
                context.canPop() &&
                bookCommand.isCompleted &&
                !bookCommand.hasError) {
              context.pop();
            }
          });
        }
      });
    } else if (!bookCommand.showSuccessMessage) {
      _hasHandledBookingSuccess = false; // Reset when message is cleared
    }

    // Handle booking error messages
    if (bookCommand.showErrorMessage && !_hasHandledBookingError) {
      _hasHandledBookingError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                bookCommand.errorMessage ??
                    'Failed to book timeslot. Please try again.',
              ),
              backgroundColor: ArkadColors.lightRed,
            ),
          );

          bookCommand.clearErrorMessage();
        }
      });
    } else if (!bookCommand.showErrorMessage) {
      _hasHandledBookingError = false; // Reset when message is cleared
    }

    // Handle unbooking success messages
    if (unbookCommand.showSuccessMessage && !_hasHandledUnbookingSuccess) {
      _hasHandledUnbookingSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unbookCommand.successMessage ??
                    'Booking cancelled successfully!',
              ),
              backgroundColor: ArkadColors.arkadGreen,
            ),
          );

          unbookCommand.clearSuccessMessage();

          // Navigate back after success (same as booking)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted &&
                context.mounted &&
                context.canPop() &&
                unbookCommand.isCompleted &&
                !unbookCommand.hasError) {
              context.pop();
            }
          });
        }
      });
    } else if (!unbookCommand.showSuccessMessage) {
      _hasHandledUnbookingSuccess = false; // Reset when message is cleared
    }

    // Handle unbooking error messages
    if (unbookCommand.showErrorMessage && !_hasHandledUnbookingError) {
      _hasHandledUnbookingError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                unbookCommand.errorMessage ??
                    'Failed to cancel booking. Please try again.',
              ),
              backgroundColor: ArkadColors.lightRed,
            ),
          );

          unbookCommand.clearErrorMessage();
        }
      });
    } else if (!unbookCommand.showErrorMessage) {
      _hasHandledUnbookingError = false; // Reset when message is cleared
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache ViewModel reference safely during didChangeDependencies
    _viewModel = Provider.of<StudentSessionViewModel>(context, listen: false);

    if (!_hasLoadedData) {
      _loadAvailableSlots();
      _hasLoadedData = true;
    }
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final provider = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      final companyId = int.tryParse(widget.id);
      if (companyId == null) {
        // Handle invalid company ID
        return;
      }

      await provider.loadTimeslots(companyId);
      final slots = provider.timeslots;

      setState(() {
        // Auto-select booked timeslot if user has one
        final bookedSlot = slots
            .where((slot) => slot.status.isBookedByCurrentUser)
            .firstOrNull;
        if (bookedSlot != null) {
          _selectedTimeslotId = bookedSlot.id;
        }
      });
    } catch (e) {
      // No need to set loading state - handled by ViewModel
      // Handle error if needed - but don't use print in production
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading time slots')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    final provider = Provider.of<StudentSessionViewModel>(
      context,
      listen: false,
    );
    final command = provider.getTimeslotsCommand;

    // Check if there's an error vs just no data
    if (command.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: ArkadColors.lightRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load timeslots',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              command.error?.userMessage ?? 'Please try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _loadAvailableSlots(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    } else {
      // Check if there are timeslots but they're not bookable due to timeline
      final provider = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      final allTimeslots = provider.timeslots;

      if (allTimeslots.isNotEmpty) {
        // Check if timeslots exist but none are selectable due to timeline restrictions
        const timelineService = TimelineValidationService.instance;
        final hasValidTimeslots = allTimeslots.any(
          (slot) => timelineService.isTimeslotBookingOpen(slot),
        );

        if (!hasValidTimeslots) {
          // All timeslots have passed their booking deadline
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  size: 64,
                  color: ArkadColors.lightRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Booking period has ended',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'All timeslots have passed their booking deadlines',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        } else {
          // Timeslots exist and some are valid, but filtered list is empty for other reasons
          return const Center(
            child: Text(
              'No available time slots match the current filter',
              style: TextStyle(fontSize: 16),
            ),
          );
        }
      } else {
        return const Center(
          child: Text(
            'No time slots available',
            style: TextStyle(fontSize: 16),
          ),
        );
      }
    }
  }

  void _confirmSelection() async {
    if (widget.isBookingMode) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );

      final companyId = int.tryParse(widget.id);
      if (companyId == null) {
        // Handle invalid company ID
        return;
      }

      // Check if user already has a booking for this company
      final currentBookedSlot = viewModel.timeslots
          .where((slot) => slot.status.isBookedByCurrentUser)
          .firstOrNull;

      final selectedSlot = _getSelectedTimeslot(viewModel.timeslots);

      if (currentBookedSlot != null &&
          (selectedSlot == null || selectedSlot.id == currentBookedSlot.id)) {
        // User wants to cancel their existing booking
        await viewModel.unbookTimeslot(companyId);
      } else if (currentBookedSlot != null &&
          selectedSlot != null &&
          selectedSlot.id != currentBookedSlot.id) {
        // User wants to change to a different timeslot
        await _changeBooking(viewModel, companyId, selectedSlot.id);
      } else if (currentBookedSlot == null && selectedSlot != null) {
        // User is booking for the first time
        await viewModel.bookTimeslot(
          companyId: companyId,
          timeslotId: selectedSlot.id,
        );
      }

      // Navigation will be handled by success/error message system
    } else {
      // Handle application flow - just navigate back for now
      context.pop();
    }
  }

  Future<void> _changeBooking(
    StudentSessionViewModel viewModel,
    int companyId,
    int newTimeslotId,
  ) async {
    // IMPROVED: Handle booking change flow with proper session management

    // First unbook the current slot (this will stop any active session)
    await viewModel.unbookTimeslot(companyId);

    // Only proceed with new booking if unbook was successful
    if (!viewModel.unbookTimeslotCommand.hasError) {
      // Start new booking (this will create a new active session)
      await viewModel.bookTimeslot(
        companyId: companyId,
        timeslotId: newTimeslotId,
      );
    }
    // If unbooking failed, the active session is already stopped by the unbook handler
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isBookingMode ? 'Book Time Slot' : 'Select Time Slot',
        ),
      ),
      body: Consumer<StudentSessionViewModel>(
        builder: (context, viewModel, child) {
          // Smart message handling with guards to prevent setState during build
          _handleCommandMessages(viewModel);

          return Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Timeslot list
                  Expanded(child: _buildTimeslotList(viewModel)),
                  // Action button for booking mode
                  if (widget.isBookingMode)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: _buildActionButton(viewModel),
                      ),
                    ),
                ],
              ),

              // Conflict overlay
              if (viewModel.showConflictOverlay)
                _buildConflictOverlay(viewModel.conflictMessage),
            ],
          );
        },
      ),
    );
  }

  /// Build simple timeslot list
  Widget _buildTimeslotList(StudentSessionViewModel viewModel) {
    // Show loading for initial load
    if (viewModel.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show empty state if no timeslots
    if (viewModel.timeslots.isEmpty) {
      return _buildEmptyState();
    }

    // Group timeslots by weekday
    final groupedSlots = _groupSlotsByWeekday(viewModel.timeslots);
    final sortedWeekdays = _getSortedWeekdays(groupedSlots);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedWeekdays.length,
      itemBuilder: (context, dayIndex) {
        final weekday = sortedWeekdays[dayIndex];
        final daySlots = groupedSlots[weekday]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              child: Text(
                weekday,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: ArkadColors.white,
                ),
              ),
            ),
            // Simple timeslot cards
            ...daySlots.map((slot) => _buildTimeslotCard(slot)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  /// Format date header in Stockholm timezone
  /// Returns format: "Tuesday (23 Sep 2025)"
  /// Note: DateTime is already in Stockholm time from mapper conversion
  String _formatDateHeader(DateTime stockholmDateTime) {
    final formatter = DateFormat('EEEE (dd MMM yyyy)', 'en_US');
    return formatter.format(stockholmDateTime);
  }

  /// Group timeslots by weekday
  Map<String, List<Timeslot>> _groupSlotsByWeekday(List<Timeslot> slots) {
    final Map<String, List<Timeslot>> groupedSlots = {};

    for (final slot in slots) {
      final weekday = _formatDateHeader(slot.startTime);

      if (!groupedSlots.containsKey(weekday)) {
        groupedSlots[weekday] = [];
      }
      groupedSlots[weekday]!.add(slot);
    }

    // Sort slots within each day by start time
    for (final daySlots in groupedSlots.values) {
      daySlots.sort((a, b) => a.startTime.compareTo(b.startTime));
    }

    return groupedSlots;
  }

  /// Get sorted weekdays
  List<String> _getSortedWeekdays(Map<String, List<Timeslot>> groupedSlots) {
    return groupedSlots.keys.toList()..sort((a, b) {
      // Get the first slot from each day to compare dates
      final dateA = groupedSlots[a]!.first.startTime;
      final dateB = groupedSlots[b]!.first.startTime;
      return dateA.compareTo(dateB);
    });
  }

  /// Build simple timeslot card
  Widget _buildTimeslotCard(Timeslot slot) {
    final isSelected = _selectedTimeslotId == slot.id;
    final isBookedByUser = slot.status.isBookedByCurrentUser;
    final isAvailable = slot.status.isAvailable;

    // Check timeline validation for this specific timeslot
    const timelineService = TimelineValidationService.instance;
    final isTimelineValid = timelineService.isTimeslotBookingOpen(slot);

    // Effective availability considers both status and timeline
    final isEffectivelyAvailable =
        (isAvailable || isBookedByUser) && isTimelineValid;

    // Determine card color and border based on status and timeline
    Color? cardColor;
    Border? cardBorder;

    if (isBookedByUser) {
      // Booked state: green background and border
      cardColor = ArkadColors.arkadGreen.withValues(alpha: 0.2);
      cardBorder = Border.all(
        color: ArkadColors.arkadGreen.withValues(alpha: 0.6),
        width: 2.5,
      );
    } else if (isSelected) {
      // Selected state: turkos background and border
      cardColor = ArkadColors.arkadTurkos.withValues(alpha: 0.2);
      cardBorder = Border.all(color: ArkadColors.arkadTurkos, width: 2);
    } else if (!isTimelineValid) {
      // Disabled/timeline invalid state: gray out
      cardColor = ArkadColors.lightGray.withValues(alpha: 0.3);
    } else {
      // Neutral state: subtle navy background
      cardColor = ArkadColors.arkadLightNavy.withValues(alpha: 0.5);
    }

    return Card(
      key: ValueKey('timeslot_${slot.id}'),
      margin: const EdgeInsets.only(bottom: 8, left: 8, right: 8),
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: cardBorder?.top ?? BorderSide.none,
      ),
      child: ListTile(
        title: Row(
          children: [
            Text(_formatTimeRange(slot)),
            if (isBookedByUser) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Booked',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArkadColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
            // Show timeline warning for any timeslot when booking has ended
            if (!isTimelineValid) ...[
              const SizedBox(width: 8),
              const Icon(
                Icons.schedule_rounded,
                color: ArkadColors.lightRed,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isBookedByUser ? 'Booking ended' : 'Booking closed',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: ArkadColors.lightRed,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: isEffectivelyAvailable
            ? RadioGroup<int>(
                groupValue: _selectedTimeslotId,
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() {
                      _selectedTimeslotId = value;
                    });
                  }
                },
                child: Radio<int>(
                  value: slot.id,
                  activeColor: isBookedByUser
                      ? ArkadColors.arkadGreen
                      : isSelected
                      ? ArkadColors.arkadTurkos
                      : null,
                ),
              )
            : RadioGroup<int>(
                groupValue: _selectedTimeslotId,
                onChanged: (int? value) {
                  // Disabled state - do nothing
                },
                child: Radio<int>(
                  value: slot.id,
                  activeColor: isBookedByUser
                      ? ArkadColors.arkadGreen
                      : isSelected
                      ? ArkadColors.arkadTurkos
                      : null,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        visualDensity: VisualDensity.compact,
        onTap: isEffectivelyAvailable
            ? () {
                setState(() {
                  _selectedTimeslotId = slot.id;
                });
              }
            : null,
        enabled: isEffectivelyAvailable,
      ),
    );
  }

  /// Format time range for display in Stockholm timezone
  String _formatTimeRange(Timeslot slot) {
    return slot.timeRangeDisplay;
  }

  /// Build simple action button
  Widget _buildActionButton(StudentSessionViewModel viewModel) {
    final timeslots = viewModel.timeslots;
    final selectedSlot = _getSelectedTimeslot(timeslots);
    final currentBookedSlot = timeslots
        .where((slot) => slot.status.isBookedByCurrentUser)
        .firstOrNull;

    // Determine button text
    String buttonText;
    if (!widget.isBookingMode) {
      buttonText = 'Confirm Selection';
    } else if (currentBookedSlot == null) {
      buttonText = selectedSlot != null
          ? 'Book Selected Timeslot'
          : 'Select a Timeslot';
    } else {
      if (selectedSlot == null || selectedSlot.id == currentBookedSlot.id) {
        buttonText = 'Cancel Booking';
      } else {
        buttonText = 'Change to Selected Timeslot';
      }
    }

    // Determine button color
    Color buttonColor;
    if (currentBookedSlot != null &&
        (selectedSlot == null || selectedSlot.id == currentBookedSlot.id)) {
      buttonColor = ArkadColors.lightRed; // Cancel action
    } else {
      buttonColor = ArkadColors.arkadTurkos; // Book or change action
    }

    // Determine if any command is executing
    final isAnyExecuting =
        viewModel.bookTimeslotCommand.isExecuting ||
        viewModel.unbookTimeslotCommand.isExecuting;

    // Determine if button is enabled
    bool isEnabled = !isAnyExecuting;
    if (widget.isBookingMode) {
      if (currentBookedSlot == null) {
        isEnabled = isEnabled && _isSelectionValid(timeslots);
      } else {
        if (selectedSlot == null || selectedSlot.id == currentBookedSlot.id) {
          isEnabled =
              isEnabled; // Cancel action - always enabled when not loading
        } else {
          isEnabled =
              isEnabled && _isSelectionValid(timeslots); // Change action
        }
      }
    } else {
      isEnabled = isEnabled && _isSelectionValid(timeslots);
    }

    return ElevatedButton(
      onPressed: isEnabled ? _confirmSelection : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: ArkadColors.white,
      ),
      child: isAnyExecuting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ArkadColors.white,
              ),
            )
          : Text(buttonText),
    );
  }

  /// Build conflict overlay (granular updates)
  Widget _buildConflictOverlay(String? message) {
    return Positioned.fill(
      child: Container(
        color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: ArkadColors.lightRed,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Booking Conflict',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message ?? 'Resolving conflict...',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Selector<StudentSessionViewModel, bool>(
                    selector: (context, viewModel) =>
                        viewModel.isHandlingConflict,
                    builder: (context, isHandling, child) {
                      if (isHandling) {
                        return const CircularProgressIndicator();
                      } else {
                        return TextButton(
                          onPressed: () {
                            final viewModel =
                                Provider.of<StudentSessionViewModel>(
                                  context,
                                  listen: false,
                                );
                            viewModel.clearConflictOverlay();
                          },
                          child: const Text('Got it'),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
