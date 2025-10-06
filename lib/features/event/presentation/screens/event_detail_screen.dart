import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../shared/errors/event_errors.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/event.dart';
import '../view_models/event_view_model.dart';
import '../widgets/event_actions.dart';
import '../widgets/event_coordinator_tools.dart';

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
    print(
      '🔍 [EventDetailScreen] initState called with eventId=${widget.eventId}',
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEvent();
    });
  }

  Future<void> _loadEvent() async {
    print('🔍 [EventDetailScreen] Loading event with ID=${widget.eventId}');
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    await eventViewModel.getEventById(widget.eventId);
    print(
      '🔍 [EventDetailScreen] Load completed. Error: ${eventViewModel.error}, Event: ${eventViewModel.selectedEvent?.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<EventViewModel, AuthViewModel>(
      builder: (context, eventViewModel, authViewModel, child) {
        final isStaff = authViewModel.currentUser?.isStaff ?? false;
        final tabCount = isStaff ? 2 : 1;

        return DefaultTabController(
          length: tabCount,
          child: Scaffold(
            body: _buildBody(eventViewModel, authViewModel, isStaff),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    EventViewModel viewModel,
    AuthViewModel authViewModel,
    bool isStaff,
  ) {
    if (viewModel.isLoading && viewModel.selectedEvent == null) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && viewModel.selectedEvent == null) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.selectedEvent == null) {
      return _buildNotFoundState();
    }

    return _buildEventDetailWithTabs(viewModel.selectedEvent!, isStaff);
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: const _LoadingAppBar(),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading event details...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(title: const Text('Event Details')),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Failed to load event',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                viewModel.error?.userMessage ?? 'Something went wrong',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ArkadButton(
                text: 'Try Again',
                onPressed: _loadEvent,
                icon: Icons.refresh_rounded,
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
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.errorContainer.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Event Not Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'The event you\'re looking for doesn\'t exist or has been removed.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ArkadButton(
                text: 'Back to Events',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back_rounded,
                variant: ArkadButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventDetailWithTabs(Event event, bool isStaff) {
    final isPastEvent = event.endTime.isBefore(DateTime.now());

    return CustomScrollView(
      slivers: [
        _buildAppBarWithTabs(event, isPastEvent, isStaff),
        SliverFillRemaining(
          child: TabBarView(
            children: [
              _buildEventDetailsTab(event, isPastEvent),
              if (isStaff) _buildCoordinatorTab(event),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventDetailsTab(Event event, bool isPastEvent) {
    return SingleChildScrollView(child: _buildEventContent(event, isPastEvent));
  }

  Widget _buildCoordinatorTab(Event event) {
    return EventCoordinatorTools(event: event);
  }

  Widget _buildAppBarWithTabs(Event event, bool isPastEvent, bool isStaff) {
    return SliverAppBar(
      //rexpandedHeight: 10.0,
      pinned: true,
      backgroundColor: _getEventTypeColor(event.type),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => context.pop(),
      ),
      title: Text(
        event.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottom: isStaff
          ? TabBar(
              tabs: [
                const Tab(text: "Details"),
                const Tab(text: "Coordinator"),
              ],
              labelColor: ArkadColors.white,
              unselectedLabelColor: ArkadColors.white.withValues(alpha: 0.7),
              indicatorColor: ArkadColors.arkadTurkos,
              indicatorWeight: 3,
            )
          : null,
    );
  }

  Widget _buildEventContent(Event event, bool isPastEvent) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('HH:mm');
    final isFull =
        event.maxParticipants != null &&
        event.currentParticipants >= event.maxParticipants!;
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
          if (!isPastEvent && !isFull)
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
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.history_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'This event has ended',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
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
      backgroundColor = Theme.of(
        context,
      ).colorScheme.errorContainer.withValues(alpha: 0.1);
      textColor = Theme.of(context).colorScheme.error;
      icon = Icons.event_busy_rounded;
      message = 'This event is fully booked';
    } else if (canRegister) {
      backgroundColor = ArkadColors.arkadGreen.withValues(alpha: 0.1);
      textColor = ArkadColors.arkadGreen;
      icon = Icons.event_available_rounded;
      message = 'Registration is open';
    } else {
      return Container(); // No banner if registration is not required or already booked
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
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
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.08),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationInfo(Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people, size: 16, color: ArkadColors.arkadTurkos),
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
    return ArkadColors.arkadTurkos;
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
        // Check if the error is an EventFullError (409 status)
        final error = eventViewModel.error;
        if (error is EventFullError) {
          // Show toast that event is full
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This event is fully booked'),
              backgroundColor: ArkadColors.lightRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
          // Navigate back
          context.pop();
          // Reload events list (trigger refresh on events screen)
          await eventViewModel.refreshEvents();
        } else {
          // Show generic error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error?.userMessage ?? 'Registration failed'),
              backgroundColor: ArkadColors.lightRed,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
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
