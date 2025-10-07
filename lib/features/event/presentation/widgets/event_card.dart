import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/event.dart';

/// Reusable event card component
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({super.key, required this.event, this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: ArkadColors.arkadLightNavy,
        elevation: 2,
        surfaceTintColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          onTap: onTap ?? () => _onEventTap(context),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getEventTypeColor(
                          event.type,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getEventTypeIcon(event.type),
                        color: _getEventTypeColor(event.type),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w400),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.type.displayName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: _getEventTypeColor(event.type),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (event.isRegistrationRequired)
                      _buildStatusIndicator(context),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${dateFormat.format(event.startTime)} • ${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        event.location,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
                // Show registration count for registration-required events
                if (event.isRegistrationRequired) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.currentParticipants}${event.maxParticipants != null ? '/${event.maxParticipants}' : ''} registered',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    // Show "Booked" badge if user has booked this event
    if (event.isBooked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ArkadColors.arkadGreen.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          'Booked',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArkadColors.arkadGreen,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Show registration status
    final canRegister = event.canRegister;
    final isFull =
        event.maxParticipants != null &&
        event.currentParticipants >= event.maxParticipants!;

    // Only show indicator for full or closed events, or when showing spots left
    if (!isFull && !(!canRegister) && event.maxParticipants == null) {
      return const SizedBox.shrink(); // Don't show "Open" for unlimited events
    }

    String statusText;
    Color backgroundColor;
    Color textColor;

    if (isFull) {
      statusText = 'Full';
      backgroundColor = Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1);
      textColor = Theme.of(context).colorScheme.error;
    } else if (!canRegister) {
      statusText = 'Closed';
      backgroundColor = Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1);
      textColor = Theme.of(context).colorScheme.error;
    } else if (event.maxParticipants != null) {
      // Show spots left for limited capacity events
      final spotsLeft = event.maxParticipants! - event.currentParticipants;
      statusText = '$spotsLeft spots left';
      backgroundColor = ArkadColors.arkadGreen.withValues(alpha: 0.1);
      textColor = ArkadColors.arkadGreen;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    return ArkadColors.arkadTurkos;
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.presentation:
        return Icons.slideshow_rounded;
      case EventType.workshop:
        return Icons.build_rounded;
      case EventType.networking:
        return Icons.people_rounded;
      case EventType.panel:
        return Icons.forum_rounded;
      case EventType.careerFair:
        return Icons.business_rounded;
      case EventType.social:
        return Icons.celebration_rounded;
    }
  }

  void _onEventTap(BuildContext context) {
    context.push('/events/detail/${event.id}');
  }
}
