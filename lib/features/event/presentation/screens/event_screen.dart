import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../view_models/event_view_model.dart';

class EventScreen extends StatefulWidget {
  const EventScreen({super.key});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvents();
    });
  }

  Future<void> _loadEvents() async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    await eventViewModel.loadEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Events'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: viewModel.isLoading ? null : _loadEvents,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadEvents,
            child: _buildBody(viewModel),
          ),
        );
      },
    );
  }

  Widget _buildBody(EventViewModel viewModel) {
    if (viewModel.isLoading && viewModel.events.isEmpty) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && viewModel.events.isEmpty) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.events.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEventsList(viewModel);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading events...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'Failed to load events',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error?.userMessage ?? 'Something went wrong',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ArkadButton(
              text: 'Try Again',
              onPressed: _loadEvents,
              icon: Icons.refresh,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.event_available,
                size: 64,
                color: ArkadColors.arkadTurkos,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Events Available',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later for upcoming ARKAD events',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ArkadButton(
              text: 'Refresh',
              onPressed: _loadEvents,
              icon: Icons.refresh,
              variant: ArkadButtonVariant.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(EventViewModel viewModel) {
    final now = DateTime.now();
    final upcomingEvents =
        viewModel.events.where((event) => event.endTime.isAfter(now)).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final pastEvents =
        viewModel.events.where((event) => event.endTime.isBefore(now)).toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcomingEvents.isNotEmpty) ...[
          _buildSectionHeader('Upcoming Events', upcomingEvents.length),
          const SizedBox(height: 8),
          ...upcomingEvents.map(_buildEventCard),
          const SizedBox(height: 24),
        ],
        if (pastEvents.isNotEmpty) ...[
          _buildSectionHeader('Past Events', pastEvents.length),
          const SizedBox(height: 8),
          ...pastEvents.map((event) => _buildEventCard(event, isPast: true)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: ArkadColors.arkadNavy,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ArkadColors.arkadTurkos,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard(Event event, {bool isPast = false}) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _onEventTap(event),
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
                      color:
                          isPast
                              ? Colors.grey.withValues(alpha: 0.1)
                              : _getEventTypeColor(
                                event.type,
                              ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getEventTypeIcon(event.type),
                      color:
                          isPast ? Colors.grey : _getEventTypeColor(event.type),
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
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPast ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.type.displayName,
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            color:
                                isPast
                                    ? Colors.grey
                                    : _getEventTypeColor(event.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (event.isRegistrationRequired && !isPast)
                    _buildRegistrationIndicator(event),
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

  Widget _buildRegistrationIndicator(Event event) {
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
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

  void _onEventTap(Event event) {
    context.push('/events/detail/${event.id}');
  }
}
