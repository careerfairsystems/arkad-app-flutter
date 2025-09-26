import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../view_models/event_view_model.dart';
import '../widgets/event_card.dart';

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
                color: ArkadColors.arkadTurkos.withOpacity(0.1),
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
          ...upcomingEvents.map(
            (event) => EventCard(event: event, status: EventStatus.upcoming),
          ),
          const SizedBox(height: 24),
        ],
        if (pastEvents.isNotEmpty) ...[
          _buildSectionHeader('Past Events', pastEvents.length),
          const SizedBox(height: 8),
          ...pastEvents.map(
            (event) => EventCard(event: event, status: EventStatus.past),
          ),
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
            color: ArkadColors.arkadTurkos.withOpacity(0.1),
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
}
