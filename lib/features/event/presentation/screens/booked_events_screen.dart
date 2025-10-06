import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../view_models/event_view_model.dart';
import '../widgets/event_card.dart';

class BookedEventsScreen extends StatefulWidget {
  const BookedEventsScreen({super.key});

  @override
  State<BookedEventsScreen> createState() => _BookedEventsScreenState();
}

class _BookedEventsScreenState extends State<BookedEventsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookedEvents();
    });
  }

  Future<void> _loadBookedEvents() async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    await eventViewModel.loadBookedEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        return RefreshIndicator(
          onRefresh: _loadBookedEvents,
          child: _buildBody(viewModel),
        );
      },
    );
  }

  Widget _buildBody(EventViewModel viewModel) {
    if (viewModel.isLoading && viewModel.bookedEvents.isEmpty) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && viewModel.bookedEvents.isEmpty) {
      return _buildErrorState(viewModel);
    }

    if (viewModel.bookedEvents.isEmpty) {
      return _buildEmptyState();
    }

    return _buildBookedEventsList(viewModel);
  }

  Widget _buildLoadingState() {
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading your booked events...'),
              ],
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ArkadColors.lightRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load booked events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error?.userMessage ?? 'Something went wrong',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ArkadButton(
                    text: 'Try Again',
                    onPressed: _loadBookedEvents,
                    icon: Icons.refresh,
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
                    child: const Icon(
                      Icons.event_note,
                      size: 64,
                      color: ArkadColors.arkadTurkos,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Booked Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You haven\'t booked any events yet. Browse available events and register for the ones that interest you!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ArkadButton(
                    text: 'Browse Events',
                    onPressed: () => context.pop(),
                    icon: Icons.explore,
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

  Widget _buildBookedEventsList(EventViewModel viewModel) {
    final sortedEvents = viewModel.bookedEvents.toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: sortedEvents.map((event) => EventCard(event: event)).toList(),
    );
  }
}
