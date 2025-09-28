import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/event.dart';

class EventCoordinatorTools extends StatelessWidget {
  final Event event;

  const EventCoordinatorTools({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildCoordinatorHeader(),
          const SizedBox(height: 24),
          _buildActionCard(
            context: context,
            icon: Icons.qr_code_scanner,
            title: 'Scan Event Tickets',
            subtitle: 'Check in attendees by scanning QR codes',
            onTap: () {
              context.push('/events/scan/${event.id}');
            },
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            context: context,
            icon: Icons.people,
            title: 'View Attendees',
            subtitle: 'See list of registered participants',
            onTap: () {
              context.push('/events/detail/${event.id}/attendees');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCoordinatorHeader() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.admin_panel_settings,
                size: 32,
                color: ArkadColors.arkadTurkos,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Coordinator Tools',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArkadColors.arkadNavy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage "${event.title}"',
              style: TextStyle(
                fontSize: 14,
                color: ArkadColors.arkadNavy.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: ArkadColors.arkadTurkos, size: 24),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: ArkadColors.arkadNavy,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: ArkadColors.arkadNavy.withValues(alpha: 0.7),
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: ArkadColors.arkadNavy.withValues(alpha: 0.5),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
