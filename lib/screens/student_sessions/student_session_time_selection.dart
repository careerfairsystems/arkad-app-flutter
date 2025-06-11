import 'package:arkad/config/theme_config.dart';
import 'package:arkad/view_models/student_session_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class StudentSessionTimeSelectionScreen extends StatefulWidget {
  final String id;

  const StudentSessionTimeSelectionScreen({required this.id, super.key});

  @override
  State<StudentSessionTimeSelectionScreen> createState() =>
      _StudentSessionTimeSelection();
}

class _StudentSessionTimeSelection
    extends State<StudentSessionTimeSelectionScreen> {
  List<TimeSlot> _availableSlots = [];
  TimeSlot? _selectedSlot;
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
      final provider = Provider.of<StudentSessionModel>(context, listen: false);
      final companyId = int.parse(widget.id);
      final slots = await provider.getAvailableSlots(companyId);

      setState(() {
        _availableSlots = slots;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Handle error
      print('Error loading time slots: $e');
    }
  }

  Map<String, List<TimeSlot>> _groupSlotsByWeekday() {
    final Map<String, List<TimeSlot>> groupedSlots = {};

    for (final slot in _availableSlots) {
      final weekday = DateFormat('EEEE (dd MMM yyyy)').format(slot.start);

      if (!groupedSlots.containsKey(weekday)) {
        groupedSlots[weekday] = [];
      }
      groupedSlots[weekday]!.add(slot);
    }

    // Sort slots within each day by start time
    for (final daySlots in groupedSlots.values) {
      daySlots.sort((a, b) => a.start.compareTo(b.start));
    }

    return groupedSlots;
  }

  List<String> _getSortedWeekdays(Map<String, List<TimeSlot>> groupedSlots) {
    return groupedSlots.keys.toList()..sort((a, b) {
      // Get the first slot from each day to compare dates
      final dateA = groupedSlots[a]!.first.start;
      final dateB = groupedSlots[b]!.first.start;
      return dateA.compareTo(dateB);
    });
  }

  String _formatTimeRange(TimeSlot slot) {
    final startTime = DateFormat('HH:mm').format(slot.start);
    final endTime = DateFormat('HH:mm').format(slot.start.add(slot.duration));
    return '$startTime - $endTime';
  }

  void _selectTimeSlot(TimeSlot slot) {
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
                                  leading: Radio<TimeSlot>(
                                    value: slot,
                                    groupValue: _selectedSlot,
                                    onChanged: (TimeSlot? value) {
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
                            }).toList(),
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
