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

  // Store ViewModel reference to prevent unsafe ancestor lookups during disposal
  StudentSessionViewModel? _viewModel;

  // Message handling state to prevent duplicates and setState during build
  bool _hasHandledBookingError = false;
  bool _hasHandledUnbookingError = false;
  bool _hasHandledSwitchError = false;

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

    // Load data in post-frame callback after widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final viewModel = Provider.of<StudentSessionViewModel>(
          context,
          listen: false,
        );

        // Reset action commands to clear their success/error messages
        viewModel.bookTimeslotCommand.reset();
        viewModel.unbookTimeslotCommand.reset();
        viewModel.switchTimeslotCommand.reset();

        // Parse and validate company ID
        final companyId = int.tryParse(widget.id);
        if (companyId == null) {
          // Handle invalid company ID in route
          if (mounted && context.mounted) {
            context.pop();
          }
          return;
        }

        // Set company context
        viewModel.setSelectedCompany(companyId);

        // Load timeslots explicitly
        _loadTimeslots(companyId, viewModel);
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

  /// Handle error messages from commands (success is handled in _confirmSelection)
  void _handleCommandMessages(StudentSessionViewModel viewModel) {
    final bookCommand = viewModel.bookTimeslotCommand;
    final unbookCommand = viewModel.unbookTimeslotCommand;
    final switchCommand = viewModel.switchTimeslotCommand;

    // Handle booking error messages
    if (bookCommand.showErrorMessage && !_hasHandledBookingError) {
      _hasHandledBookingError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Skip SnackBar for conflicts - unified overlay handles them
          if (!bookCommand.isBookingConflict) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  bookCommand.errorMessage ??
                      'Failed to book timeslot. Please try again.',
                ),
                backgroundColor: ArkadColors.lightRed,
              ),
            );
          }

          bookCommand.clearErrorMessage();
        }
      });
    } else if (!bookCommand.showErrorMessage) {
      _hasHandledBookingError = false; // Reset when message is cleared
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

    // Handle switch error messages
    if (switchCommand.showErrorMessage && !_hasHandledSwitchError) {
      _hasHandledSwitchError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Skip SnackBar for conflicts - unified overlay handles them
          if (!switchCommand.isTimeslotConflict) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  switchCommand.errorMessage ??
                      'Failed to switch timeslot. Please try again.',
                ),
                backgroundColor: ArkadColors.lightRed,
              ),
            );
          }

          switchCommand.clearErrorMessage();
        }
      });
    } else if (!switchCommand.showErrorMessage) {
      _hasHandledSwitchError = false; // Reset when message is cleared
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Cache ViewModel reference safely during didChangeDependencies
    _viewModel = Provider.of<StudentSessionViewModel>(context, listen: false);
  }

  /// Load timeslots and update local state after completion
  Future<void> _loadTimeslots(
    int companyId,
    StudentSessionViewModel viewModel,
  ) async {
    try {
      // Load timeslots from API
      await viewModel.loadTimeslots(companyId);

      // Update local state after load completes
      if (mounted) {
        setState(() {
          // Auto-select booked timeslot if user has one
          final bookedSlot = viewModel.timeslots
              .where((slot) => slot.status.isBookedByCurrentUser)
              .firstOrNull;
          if (bookedSlot != null) {
            _selectedTimeslotId = bookedSlot.id;
          }
        });
      }
    } catch (e) {
      // Errors are handled by command and shown in UI
      // Only show user-facing error if needed
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
              onPressed: () {
                final viewModel = Provider.of<StudentSessionViewModel>(
                  context,
                  listen: false,
                );
                final companyId = int.tryParse(widget.id);
                if (companyId != null) {
                  _loadTimeslots(companyId, viewModel);
                }
              },
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

        // Navigate immediately after successful unbooking
        if (mounted &&
            viewModel.unbookTimeslotCommand.isCompleted &&
            !viewModel.unbookTimeslotCommand.hasError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Booking cancelled successfully!'),
                backgroundColor: ArkadColors.arkadGreen,
                duration: Duration(seconds: 2),
              ),
            );
            context.pop();
          }
        }
      } else if (currentBookedSlot != null &&
          selectedSlot != null &&
          selectedSlot.id != currentBookedSlot.id) {
        // User wants to change to a different timeslot
        await _changeBooking(viewModel, companyId, selectedSlot.id);

        // Navigate immediately after successful switch
        if (mounted &&
            viewModel.switchTimeslotCommand.isCompleted &&
            !viewModel.switchTimeslotCommand.hasError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Timeslot switched successfully!'),
                backgroundColor: ArkadColors.arkadGreen,
                duration: Duration(seconds: 2),
              ),
            );
            context.pop();
          }
        }
      } else if (currentBookedSlot == null && selectedSlot != null) {
        // User is booking for the first time
        await viewModel.bookTimeslot(
          companyId: companyId,
          timeslotId: selectedSlot.id,
        );

        // Navigate immediately after successful booking
        if (mounted &&
            viewModel.bookTimeslotCommand.isCompleted &&
            !viewModel.bookTimeslotCommand.hasError) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Timeslot booked successfully!'),
                backgroundColor: ArkadColors.arkadGreen,
                duration: Duration(seconds: 2),
              ),
            );
            context.pop();
          }
        }
      }
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
    // ATOMIC SWITCH: Use single API call to prevent race conditions

    // Get current booked timeslot ID
    final currentBookedSlot = viewModel.timeslots
        .where((slot) => slot.status.isBookedByCurrentUser)
        .firstOrNull;

    if (currentBookedSlot == null) {
      // Should not happen, but handle gracefully
      // Fall back to regular booking if no existing booking found
      await viewModel.bookTimeslot(
        companyId: companyId,
        timeslotId: newTimeslotId,
      );
      return;
    }

    // Use atomic switch endpoint - prevents race conditions
    await viewModel.switchTimeslot(
      fromTimeslotId: currentBookedSlot.id,
      newTimeslotId: newTimeslotId,
    );
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

  /// Build simple timeslot list with proper loading states
  Widget _buildTimeslotList(StudentSessionViewModel viewModel) {
    // Show loading for initial load
    if (viewModel.isInitialLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading timeslots...'),
          ],
        ),
      );
    }

    // Show empty state if no timeslots
    if (viewModel.timeslots.isEmpty) {
      return _buildEmptyState();
    }

    return _buildTimeslotListContent(viewModel);
  }

  /// Build the actual timeslot list content
  Widget _buildTimeslotListContent(StudentSessionViewModel viewModel) {
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
        viewModel.unbookTimeslotCommand.isExecuting ||
        viewModel.switchTimeslotCommand.isExecuting ||
        viewModel.getTimeslotsCommand.isExecuting;

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
