import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/event.dart';
import '../../services/event_service.dart';
import '../../utils/service_helper.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreen();
}

class _EventScreen extends State<EventScreen> {
  late final EventService _eventService;

  List<Event> _events = List.empty();

  @override
  void initState() {
    super.initState();
    _eventService = ServiceHelper.getService<EventService>();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {});

    try {
      final events = await _eventService.getAllEvents();
      setState(() {
        print(events);
        _events = events;
      });
    } catch (e) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Upcoming Events',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Check out all the events happening in ARKAD',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () {
                    context.go('/events/scan');
                  },
                  icon: const Icon(Icons.crop_free),
                  // make only visible for some users
                  label: const Text("Scan QR code"),
                ),
                TextButton.icon(
                  onPressed: () {
                    context.go('/events/tickets');
                  },
                  icon: const Icon(Icons.restaurant),
                  label: const Text("My tickets"),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _events.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.star, color: Colors.white),
        ),
        title: Text('Event ${index + 1}'),
        subtitle: Text(
          'Location: Building ${index + 1}, Room ${(index + 1) * 100}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
