import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../features/notifications/data/services/fcm_service.dart';
import '../../../features/notifications/presentation/view_models/notification_view_model.dart';
import '../themes/arkad_theme.dart';
import 'arkad_button.dart';

/// Card that displays notification permission status and allows users to enable notifications
class NotificationStatusCard extends StatefulWidget {
  const NotificationStatusCard({super.key});

  @override
  State<NotificationStatusCard> createState() => _NotificationStatusCardState();
}

class _NotificationStatusCardState extends State<NotificationStatusCard> {
  static const String _dismissedKey = 'notification_card_dismissed';
  bool _isDismissed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDismissed = prefs.getBool(_dismissedKey) ?? false;
      _isLoading = false;
    });
  }

  Future<void> _dismissCard() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dismissedKey, true);
    setState(() {
      _isDismissed = true;
    });
  }

  Future<void> _openSettings() async {
    await FcmService.instance.openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isDismissed) {
      return const SizedBox.shrink();
    }

    return Consumer<NotificationViewModel>(
      builder: (context, notificationViewModel, child) {
        // Only show card when FCM is initialized
        if (!notificationViewModel.isInitialized) {
          return const SizedBox.shrink();
        }

        final permissionGranted = notificationViewModel.permissionGranted;

        // Choose colors and content based on permission status
        final backgroundColor = permissionGranted
            ? ArkadColors.arkadGreen.withValues(alpha: 0.1)
            : ArkadColors.arkadOrange.withValues(alpha: 0.1);
        final borderColor = permissionGranted
            ? ArkadColors.arkadGreen.withValues(alpha: 0.3)
            : ArkadColors.arkadOrange.withValues(alpha: 0.3);
        final iconColor = permissionGranted
            ? ArkadColors.arkadGreen
            : ArkadColors.arkadOrange;
        final icon = permissionGranted
            ? Icons.notifications_active
            : Icons.notifications_off_outlined;
        final title = permissionGranted
            ? 'Notifications Enabled'
            : 'Notifications Disabled';
        final message = permissionGranted
            ? 'You\'ll receive updates about career fair events and sessions.'
            : 'Enable notifications to stay updated about career fair events and sessions.';

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: iconColor, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ArkadColors.gray,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _dismissCard,
                    color: ArkadColors.gray,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: ArkadColors.gray.withValues(alpha: 0.8),
                ),
              ),
              if (!permissionGranted) ...[
                const SizedBox(height: 12),
                ArkadButton(
                  text: 'Enable Notifications',
                  onPressed: _openSettings,
                  variant: ArkadButtonVariant.secondary,
                  size: ArkadButtonSize.small,
                  icon: Icons.settings,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
