import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/event.dart';

/// Status of an event for display purposes
enum EventStatus { upcoming, booked, past }

/// Reusable event card component
class EventCard extends StatelessWidget {
  final Event event;
  final EventStatus status;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isPast = status == EventStatus.past;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap ?? () => _onEventTap(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPast
                          ? Colors.grey.withValues(alpha: 0.1)
                          : _getEventTypeColor(
                              event.type,
                            ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.type),
                      color: isPast
                          ? Colors.grey
                          : _getEventTypeColor(event.type),
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
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isPast ? Colors.grey : null,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.type.displayName,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isPast
                                    ? Colors.grey
                                    : _getEventTypeColor(event.type),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  if (event.isRegistrationRequired && !isPast)
                    _buildStatusIndicator(context),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isPast ? Colors.grey : Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: isPast ? Colors.grey : ArkadColors.arkadTurkos,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${dateFormat.format(event.startTime)} • ${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isPast ? Colors.grey : Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: isPast ? Colors.grey : ArkadColors.arkadTurkos,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPast ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              // Show registration count for registration-required events
              if (event.isRegistrationRequired && !isPast) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.people,
                      size: 16,
                      color: isPast ? Colors.grey : ArkadColors.arkadTurkos,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${event.currentParticipants}${event.maxParticipants != null ? '/${event.maxParticipants}' : ''} registered',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isPast ? Colors.grey : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    if (status == EventStatus.booked) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Booked',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArkadColors.arkadGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // For upcoming events, show registration status
    final canRegister = event.canRegister;
    final isFull =
        event.maxParticipants != null &&
        event.currentParticipants >= event.maxParticipants!;

    // Only show indicator for full or closed events, or when showing spots left
    if (!isFull && !(!canRegister) && event.maxParticipants == null) {
      return const SizedBox.shrink(); // Don't show "Open" for unlimited events
    }

    String statusText;
    Color color;

    if (isFull) {
      statusText = 'Full';
      color = ArkadColors.lightRed;
    } else if (!canRegister) {
      statusText = 'Closed';
      color = ArkadColors.lightRed;
    } else if (event.maxParticipants != null) {
      // Show spots left for limited capacity events
      final spotsLeft = event.maxParticipants! - event.currentParticipants;
      statusText = '$spotsLeft spots left';
      color = ArkadColors.arkadGreen;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: ArkadColors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getEventTypeColor(EventType type) {
    switch (type) {
      case EventType.presentation:
        return ArkadColors.arkadTurkos;
      case EventType.workshop:
        return ArkadColors.arkadGreen;
      case EventType.networking:
        return ArkadColors.arkadOrange;
      case EventType.panel:
        return ArkadColors.arkadSkog;
      case EventType.careerFair:
        return ArkadColors.arkadNavy;
      case EventType.social:
        return ArkadColors.accenture;
    }
  }

  IconData _getEventTypeIcon(EventType type) {
    switch (type) {
      case EventType.presentation:
        return Icons.slideshow;
      case EventType.workshop:
        return Icons.build;
      case EventType.networking:
        return Icons.people;
      case EventType.panel:
        return Icons.forum;
      case EventType.careerFair:
        return Icons.business;
      case EventType.social:
        return Icons.celebration;
    }
  }

  void _onEventTap(BuildContext context) {
    context.push('/events/detail/${event.id}');
  }
}
