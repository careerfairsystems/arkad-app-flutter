import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

class StaffActionsScreen extends StatelessWidget {
  const StaffActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          _buildActionCard(
            context: context,
            icon: Icons.qr_code_scanner,
            title: 'Scan event ticket',
            subtitle: 'Scan QR codes to check in attendees',
            onTap: () {
              context.push('/events/scan');
            },
          ),
          const SizedBox(height: 16),
          // Future actions can be added here
          // _buildActionCard(
          //   context: context,
          //   icon: Icons.analytics,
          //   title: 'Analytics Dashboard',
          //   subtitle: 'View event and attendance statistics',
          //   onTap: () => context.push('/staff/analytics'),
          // ),
          // _buildActionCard(
          //   context: context,
          //   icon: Icons.people,
          //   title: 'Manage Attendees',
          //   subtitle: 'View and manage event registrations',
          //   onTap: () => context.push('/staff/attendees'),
          // ),
        ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
          child: Icon(
            icon,
            color: ArkadColors.arkadTurkos,
            size: 24,
          ),
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