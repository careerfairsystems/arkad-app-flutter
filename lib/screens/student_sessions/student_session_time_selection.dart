import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/student_session_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    try {
      final provider = Provider.of<StudentSessionProvider>(
        context,
        listen: false,
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load time slots: $e')));
    }
  }

  String _formatTimeSlot(TimeSlot slot) {
    final startTime = DateFormat('HH:mm').format(slot.start);
    final endTime = DateFormat(
      'HH:mm',
    ).format(slot.start.add(slot.duration)); // Use slot.duration directly
    final date = DateFormat('MMM dd, yyyy').format(slot.start);
    return '$date: $startTime - $endTime';
  }

  void _selectTimeSlot(TimeSlot slot) {
    setState(() {
      _selectedSlot = slot;
    });
  }

  void _confirmSelection() {
    if (_selectedSlot != null) {
      // Handle the confirmed selection
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Time slot selected: ${_formatTimeSlot(_selectedSlot!)}',
          ),
        ),
      );
      // Navigate back or to next screen
      Navigator.of(context).pop(_selectedSlot);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      itemCount: _availableSlots.length,
                      itemBuilder: (context, index) {
                        final slot = _availableSlots[index];
                        final isSelected = _selectedSlot == slot;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(_formatTimeSlot(slot)),
                            selected: isSelected,
                            selectedTileColor: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.1),
                            leading: Radio<TimeSlot>(
                              value: slot,
                              groupValue: _selectedSlot,
                              onChanged: (TimeSlot? value) {
                                if (value != null) {
                                  _selectTimeSlot(value);
                                }
                              },
                            ),
                            onTap: () => _selectTimeSlot(slot),
                          ),
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
