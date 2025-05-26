import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Events')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () {
                context.go('/events/scan');
              },
              icon: const Icon(Icons.crop_free),
              label: const Text("Scan QR code"),
            ),
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
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (context, index) {
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
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
