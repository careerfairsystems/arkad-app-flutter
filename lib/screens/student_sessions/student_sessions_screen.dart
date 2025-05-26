import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentSessionsScreen extends StatelessWidget {
  const StudentSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Sessions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Student Sessions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'View and manage your booked sessions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(Icons.calendar_today)),
                      title: Text('Session with Company ${index + 1}'),
                      subtitle: Text('Date: Nov ${index + 10}, 2023'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/sessions/apply/${index + 1}'),
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
