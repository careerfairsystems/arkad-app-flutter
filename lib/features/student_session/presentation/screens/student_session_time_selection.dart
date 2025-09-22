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
  List<Timeslot> _availableSlots = [];
  Timeslot? _selectedSlot;
  bool _isLoading = true;
  bool _hasLoadedData = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
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
      final companyId = int.parse(widget.id);
      
      await provider.loadTimeslots(companyId);
      final slots = provider.timeslots;

      setState(() {
        _availableSlots = slots;
        _isLoading = false;
        
        // Auto-select booked timeslot if user has one
        final bookedSlot = slots
            .where((slot) => slot.status.isBookedByCurrentUser)
            .firstOrNull;
        if (bookedSlot != null) {
          _selectedSlot = bookedSlot;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error if needed - but don't use print in production
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading time slots')));
      }
    }
  }

  Map<String, List<Timeslot>> _groupSlotsByWeekday() {
    final Map<String, List<Timeslot>> groupedSlots = {};

    for (final slot in _availableSlots) {
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

  List<String> _getSortedWeekdays(Map<String, List<Timeslot>> groupedSlots) {
    return groupedSlots.keys.toList()..sort((a, b) {
      // Get the first slot from each day to compare dates
      final dateA = groupedSlots[a]!.first.startTime;
      final dateB = groupedSlots[b]!.first.startTime;
      return dateA.compareTo(dateB);
    });
  }

  String _formatTimeRange(Timeslot slot) {
    final startTime = DateFormat('HH:mm').format(slot.startTime);
    final endTime = DateFormat('HH:mm').format(slot.endTime);
    return '$startTime - $endTime';
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
            Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'Failed to load timeslots',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              command.error?.userMessage ?? 'Please try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
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
        child: Text(
          'No time slots available',
          style: TextStyle(fontSize: 16),
        ),
      );
    }
  }


  String _getButtonText() {
    if (!widget.isBookingMode) {
      return 'Confirm Selection';
    }
    
    // Check if user has an existing booking
    final currentBookedSlot = _availableSlots
        .where((slot) => slot.status.isBookedByCurrentUser)
        .firstOrNull;
    
    if (currentBookedSlot == null) {
      // No existing booking - show book button
      return _selectedSlot != null ? 'Book Selected Timeslot' : 'Select a Timeslot';
    } else {
      // Has existing booking - show cancel or change based on selection
      if (_selectedSlot == null || _selectedSlot == currentBookedSlot) {
        return 'Cancel Booking';
      } else {
        return 'Change to Selected Timeslot';
      }
    }
  }

  void _selectTimeSlot(Timeslot slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _confirmSelection() async {
    if (widget.isBookingMode) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      
      final companyId = int.parse(widget.id);
      
      // Check if user already has a booking for this company
      final currentBookedSlot = _availableSlots
          .where((slot) => slot.status.isBookedByCurrentUser)
          .firstOrNull;
      
      if (currentBookedSlot != null && (_selectedSlot == null || _selectedSlot == currentBookedSlot)) {
        // User wants to cancel their existing booking
        await viewModel.unbookTimeslot(companyId);
      } else if (currentBookedSlot != null && _selectedSlot != currentBookedSlot) {
        // User wants to change to a different timeslot
        await _changeBooking(viewModel, companyId, _selectedSlot!.id);
      } else if (currentBookedSlot == null && _selectedSlot != null) {
        // User is booking for the first time
        await viewModel.bookTimeslot(
          companyId: companyId,
          timeslotId: _selectedSlot!.id,
        );
      }
      
      // Navigation will be handled by success/error message system
    } else {
      // Handle application flow - just navigate back for now
      context.pop();
    }
  }

  Future<void> _changeBooking(StudentSessionViewModel viewModel, int companyId, int newTimeslotId) async {
    // First unbook the current slot
    await viewModel.unbookTimeslot(companyId);
    
    // Only proceed with new booking if unbook was successful
    if (!viewModel.unbookTimeslotCommand.hasError) {
      await viewModel.bookTimeslot(
        companyId: companyId,
        timeslotId: newTimeslotId,
      );
    }
  }

  Widget _buildActionButton(bool isLoading) {
    final buttonText = _getButtonText();
    final currentBookedSlot = _availableSlots
        .where((slot) => slot.status.isBookedByCurrentUser)
        .firstOrNull;
    
    // Determine button color based on action
    Color? buttonColor;
    if (currentBookedSlot != null && (_selectedSlot == null || _selectedSlot == currentBookedSlot)) {
      // Cancel action - red
      buttonColor = ArkadColors.lightRed;
    } else {
      // Book or change action - blue
      buttonColor = ArkadColors.arkadTurkos;
    }

    // Determine if button should be enabled
    bool isEnabled = !isLoading;
    if (widget.isBookingMode) {
      if (currentBookedSlot == null) {
        // First time booking - need selection
        isEnabled = isEnabled && _selectedSlot != null;
      } else {
        // Has existing booking - always enabled for cancel/change
        isEnabled = isEnabled; // Always enabled when not loading
      }
    } else {
      // Application mode - need selection
      isEnabled = isEnabled && _selectedSlot != null;
    }

    return ElevatedButton(
      onPressed: isEnabled ? _confirmSelection : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        foregroundColor: Colors.white,
      ),
      child: isLoading 
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(buttonText),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groupedSlots = _groupSlotsByWeekday();
    final sortedWeekdays = _getSortedWeekdays(groupedSlots);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isBookingMode ? 'Book Time Slot' : 'Select Time Slot'),
      ),
      body: widget.isBookingMode 
          ? Consumer<StudentSessionViewModel>(
              builder: (context, viewModel, child) {
                // Handle booking success/error messages
                if (viewModel.showSuccessMessage) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(viewModel.successMessage ?? 'Timeslot booked successfully!'),
                          backgroundColor: ArkadColors.arkadGreen,
                        ),
                      );
                      
                      // Clear the message flag
                      viewModel.clearSuccessMessage();
                      
                      // Navigate back after a short delay
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (mounted && context.mounted && context.canPop()) {
                          context.pop();
                        }
                      });
                    }
                  });
                }
                
                // Handle booking errors
                if (viewModel.showErrorMessage) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      final errorMessage = viewModel.errorMessage ?? 'Failed to book timeslot. Please try again.';
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(errorMessage),
                          backgroundColor: ArkadColors.lightRed,
                        ),
                      );
                      
                      // Clear the message flag
                      viewModel.clearErrorMessage();
                    }
                  });
                }
                
                return _buildTimeSelectionBody(groupedSlots, sortedWeekdays, viewModel.bookTimeslotCommand.isExecuting);
              },
            )
          : _buildTimeSelectionBody(groupedSlots, sortedWeekdays, false),
    );
  }

  Widget _buildTimeSelectionBody(Map<String, List<Timeslot>> groupedSlots, List<String> sortedWeekdays, bool isBooking) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _availableSlots.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedWeekdays.length,
                      itemBuilder: (context, dayIndex) {
                        final weekday = sortedWeekdays[dayIndex];
                        final daySlots = groupedSlots[weekday]!;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              child: Text(
                                weekday,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ),
                            ...daySlots.map((slot) {
                              final isSelected = _selectedSlot == slot;
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
                                margin: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                ),
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
                                        Icon(
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
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Radio<Timeslot>(
                                    value: slot,
                                    groupValue: _selectedSlot,
                                    activeColor: isBookedByUser ? ArkadColors.arkadGreen : null,
                                    onChanged: (isAvailable || isBookedByUser) ? (Timeslot? value) {
                                      if (value != null) {
                                        _selectTimeSlot(value);
                                      }
                                    } : null,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onTap: (isAvailable || isBookedByUser) ? () => _selectTimeSlot(slot) : null,
                                  enabled: (isAvailable || isBookedByUser),
                                ),
                              );
                            }),
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: _buildActionButton(isBooking),
                    ),
                  ),
                ],
              );
  }
}
