import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

    // Debug: Log loaded event IDs
    print('🔍 [EventScreen] Loaded ${eventViewModel.events.length} events');
    for (final event in eventViewModel.events) {
      print('   - Event ID: ${event.id}, Title: ${event.title}');
    }
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
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
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
                    'Loading events...',
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
        ),
      ],
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.errorContainer.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.error.withValues(alpha: 0.1),
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
                    'Failed to load events',
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
                    onPressed: _loadEvents,
                    icon: Icons.refresh_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(32),
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.event_available_rounded,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Events Available',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Check back later for ARKAD events',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ArkadButton(
                    text: 'Refresh',
                    onPressed: _loadEvents,
                    icon: Icons.refresh_rounded,
                    variant: ArkadButtonVariant.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEventsList(EventViewModel viewModel) {
    final events = viewModel.events.toList()
      ..removeWhere((event) => event.hasEnded)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: events.map((event) => EventCard(event: event)).toList(),
    );
  }
}
