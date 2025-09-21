import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../view_models/event_view_model.dart';
import '../widgets/event_actions.dart';

class EventDetailScreen extends StatefulWidget {
  final int eventId;

  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  Future<void> _loadEvent() async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    await eventViewModel.getEventById(widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(body: _buildBody(viewModel));
      },
    );
  }

  Widget _buildBody(EventViewModel viewModel) {
    if (viewModel.isLoading && viewModel.selectedEvent == null) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && viewModel.selectedEvent == null) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.selectedEvent == null) {
      return _buildNotFoundState();
    }

    return _buildEventDetail(viewModel.selectedEvent!);
  }

  Widget _buildLoadingState() {
    return const Scaffold(
      appBar: _LoadingAppBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading event details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
              const SizedBox(height: 16),
              Text(
                'Failed to load event',
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
                onPressed: _loadEvent,
                icon: Icons.refresh,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 64, color: ArkadColors.lightRed),
              const SizedBox(height: 16),
              Text(
                'Event Not Found',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ArkadButton(
                text: 'Back to Events',
                onPressed: () => Navigator.of(context).pop(),
                icon: Icons.arrow_back,
                variant: ArkadButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetail(Event event) {
    final isPastEvent = event.endTime.isBefore(DateTime.now());

    return CustomScrollView(
      slivers: [
        _buildAppBar(event, isPastEvent),
        SliverToBoxAdapter(child: _buildEventContent(event, isPastEvent)),
      ],
    );
  }

  Widget _buildAppBar(Event event, bool isPastEvent) {
    return SliverAppBar(
      expandedHeight: 200.0,
      pinned: true,
      backgroundColor: _getEventTypeColor(event.type),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          event.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _getEventTypeColor(event.type),
                _getEventTypeColor(event.type).withValues(alpha: 0.8),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // Account for status bar
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    _getEventTypeIcon(event.type),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventContent(Event event, bool isPastEvent) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Status Banner
          if (isPastEvent) _buildPastEventBanner(),
          if (!isPastEvent && event.isRegistrationRequired)
            _buildRegistrationBanner(event),

          const SizedBox(height: 16),

          // Description
          _buildSection(
            'About This Event',
            Icons.info_outline,
            Text(
              event.description,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
          ),

          const SizedBox(height: 24),

          // Date & Time
          _buildSection(
            'Date & Time',
            Icons.schedule,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateFormat.format(event.startTime),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timeFormat.format(event.startTime)} - ${timeFormat.format(event.endTime)}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: ArkadColors.arkadTurkos,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Duration: ${_formatDuration(event.duration)}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Location
          _buildSection(
            'Location',
            Icons.location_on,
            Text(
              event.location,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          // Registration Info
          if (event.isRegistrationRequired) ...[
            const SizedBox(height: 24),
            _buildSection(
              'Registration',
              Icons.people,
              _buildRegistrationInfo(event),
            ),
          ],

          const SizedBox(height: 32),

          // Action Button
          if (!isPastEvent)
            EventActions(
              event: event,
              onRegister: () => _registerForEvent(event),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPastEventBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Colors.grey[600], size: 20),
          const SizedBox(width: 8),
          Text(
            'This event has ended',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegistrationBanner(Event event) {
    final canRegister = event.canRegister;
    final isFull =
        event.maxParticipants != null &&
        event.currentParticipants >= event.maxParticipants!;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    if (isFull) {
      backgroundColor = ArkadColors.lightRed.withValues(alpha: 0.1);
      textColor = ArkadColors.lightRed;
      icon = Icons.event_busy;
      message = 'This event is fully booked';
    } else if (canRegister) {
      backgroundColor = ArkadColors.arkadGreen.withValues(alpha: 0.1);
      textColor = ArkadColors.arkadGreen;
      icon = Icons.event_available;
      message = 'Registration is open';
    } else {
      backgroundColor = ArkadColors.lightRed.withValues(alpha: 0.1);
      textColor = ArkadColors.lightRed;
      icon = Icons.event_busy;
      message = 'Registration is closed';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: textColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: ArkadColors.arkadTurkos),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: ArkadColors.arkadNavy,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  Widget _buildRegistrationInfo(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 16, color: ArkadColors.arkadTurkos),
            const SizedBox(width: 4),
            Text(
              '${event.currentParticipants}${event.maxParticipants != null ? '/${event.maxParticipants}' : ''} participants',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        if (event.maxParticipants != null) ...[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: event.currentParticipants / event.maxParticipants!,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              event.currentParticipants >= event.maxParticipants!
                  ? ArkadColors.lightRed
                  : ArkadColors.arkadGreen,
            ),
          ),
        ],
      ],
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

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Future<void> _registerForEvent(Event event) async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    final success = await eventViewModel.registerForEvent(event.id);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered for ${event.title}'),
            backgroundColor: ArkadColors.arkadGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // Refresh the event details to show updated participant count
        await _loadEvent();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              eventViewModel.error?.userMessage ?? 'Registration failed',
            ),
            backgroundColor: ArkadColors.lightRed,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _LoadingAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _LoadingAppBar();

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Loading...'));
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
