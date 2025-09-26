import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../view_models/student_session_view_model.dart';

class StudentSessionTimeSelectionScreen extends StatefulWidget {
  final String id;

  const StudentSessionTimeSelectionScreen({required this.id, super.key});

  @override
  State<StudentSessionTimeSelectionScreen> createState() =>
      _StudentSessionTimeSelection();
}

class _StudentSessionTimeSelection
    extends State<StudentSessionTimeSelectionScreen> {
  List<TimeslotSchema> _availableSlots = [];
  TimeslotSchema? _selectedSlot;
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
      final slots = provider.availableTimeslots;

      // Convert Timeslot domain entities to TimeslotSchema for compatibility
      final schemSlots =
          slots
              .map(
                (slot) => TimeslotSchema(
                  (b) =>
                      b
                        ..id = slot.id
                        ..startTime = slot.startTime
                        ..duration =
                            slot.endTime.difference(slot.startTime).inMinutes,
                ),
              )
              .toList();

      setState(() {
        _availableSlots = schemSlots;
        _isLoading = false;
      });
    } catch (e) {
      await Sentry.captureException(e);
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading time slots: $e');
    }
  }

  Map<String, List<TimeslotSchema>> _groupSlotsByWeekday() {
    final Map<String, List<TimeslotSchema>> groupedSlots = {};

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

  List<String> _getSortedWeekdays(
    Map<String, List<TimeslotSchema>> groupedSlots,
  ) {
    return groupedSlots.keys.toList()..sort((a, b) {
      // Get the first slot from each day to compare dates
      final dateA = groupedSlots[a]!.first.startTime;
      final dateB = groupedSlots[b]!.first.startTime;
      return dateA.compareTo(dateB);
    });
  }

  String _formatTimeRange(TimeslotSchema slot) {
    final startTime = DateFormat('HH:mm').format(slot.startTime);
    final endTime = DateFormat(
      'HH:mm',
    ).format(slot.startTime.add(Duration(minutes: slot.duration)));
    return '$startTime - $endTime';
  }

  void _selectTimeSlot(TimeslotSchema slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  //TODO: Navigate to next screen? Maybe profile overview of the session?
  void _confirmSelection() {
    if (_selectedSlot != null) {
      // Handle the confirmed selection
      print('Selected time slot: $_selectedSlot');
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedSlots = _groupSlotsByWeekday();
    final sortedWeekdays = _getSortedWeekdays(groupedSlots);

    return Scaffold(
      appBar: AppBar(title: const Text('Select Time Slot')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _availableSlots.isEmpty
              ? const Center(
                child: Text(
                  'No available time slots',
                  style: TextStyle(fontSize: 16),
                ),
              )
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

                              return Card(
                                margin: const EdgeInsets.only(
                                  bottom: 8,
                                  left: 8,
                                  right: 8,
                                ),
                                color:
                                    isSelected ? ArkadColors.lightGray : null,
                                child: ListTile(
                                  title: Text(_formatTimeRange(slot)),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  leading: Radio<TimeslotSchema>(
                                    value: slot,
                                    // ignore: deprecated_member_use
                                    groupValue: _selectedSlot,
                                    // ignore: deprecated_member_use
                                    onChanged: (TimeslotSchema? value) {
                                      if (value != null) {
                                        _selectTimeSlot(value);
                                      }
                                    },
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 6,
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  onTap: () => _selectTimeSlot(slot),
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
                      child: ElevatedButton(
                        onPressed:
                            _selectedSlot != null ? _confirmSelection : null,
                        child: const Text('Confirm Selection'),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }
}
