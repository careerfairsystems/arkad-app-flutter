import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/timeslot.dart';
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

  /// Check if current selection is valid (exists and is available)
  bool _isSelectionValid(List<Timeslot> timeslots) {
    final selectedSlot = _getSelectedTimeslot(timeslots);
    return selectedSlot != null &&
        (selectedSlot.status.isAvailable ||
            selectedSlot.status.isBookedByCurrentUser);
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
      return const Center(
        child: Text('No time slots available', style: TextStyle(fontSize: 16)),
      );
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
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Theme.of(context).primaryColor,
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

  /// Group timeslots by weekday
  Map<String, List<Timeslot>> _groupSlotsByWeekday(List<Timeslot> slots) {
    final Map<String, List<Timeslot>> groupedSlots = {};

    for (final slot in slots) {
      final weekday = DateFormat('EEEE (dd MMM yyyy)').format(slot.startTime);

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

    // Determine card color based on status
    Color? cardColor;
    if (isBookedByUser) {
      cardColor = ArkadColors.arkadGreen.withValues(alpha: 0.2);
    } else if (isSelected) {
      cardColor = ArkadColors.lightGray;
    }

    // Border for booked slots
    Border? cardBorder;
    if (isBookedByUser) {
      cardBorder = Border.all(
        color: ArkadColors.arkadGreen.withValues(alpha: 0.6),
        width: 2.5,
      );
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
              const Icon(
                Icons.check_circle_rounded,
                color: ArkadColors.arkadGreen,
                size: 20,
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Booked by you',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: ArkadColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: (isAvailable || isBookedByUser)
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
                  activeColor: isBookedByUser ? ArkadColors.arkadGreen : null,
                ),
              )
            : RadioGroup<int>(
                groupValue: _selectedTimeslotId,
                onChanged: (int? value) {
                  // Disabled state - do nothing
                },
                child: Radio<int>(
                  value: slot.id,
                  activeColor: isBookedByUser ? ArkadColors.arkadGreen : null,
                ),
              ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        visualDensity: VisualDensity.compact,
        onTap: (isAvailable || isBookedByUser)
            ? () {
                setState(() {
                  _selectedTimeslotId = slot.id;
                });
              }
            : null,
        enabled: (isAvailable || isBookedByUser),
      ),
    );
  }

  /// Format time range for display
  String _formatTimeRange(Timeslot slot) {
    final startTime = DateFormat('HH:mm').format(slot.startTime);
    final endTime = DateFormat('HH:mm').format(slot.endTime);
    return '$startTime - $endTime';
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
