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
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading your booked events...'),
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
              'Failed to load booked events',
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
              onPressed: _loadBookedEvents,
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
                Icons.event_note,
                size: 64,
                color: ArkadColors.arkadTurkos,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Booked Events',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'You haven\'t booked any events yet. Browse available events and register for the ones that interest you!',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
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
    );
  }

  Widget _buildBookedEventsList(EventViewModel viewModel) {
    final now = DateTime.now();
    final upcomingBookedEvents =
        viewModel.bookedEvents
            .where((event) => event.endTime.isAfter(now))
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final pastBookedEvents =
        viewModel.bookedEvents
            .where((event) => event.endTime.isBefore(now))
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (upcomingBookedEvents.isNotEmpty) ...[
          _buildSectionHeader('Upcoming Events', upcomingBookedEvents.length),
          const SizedBox(height: 8),
          ...upcomingBookedEvents.map(
            (event) => EventCard(event: event, status: EventStatus.booked),
          ),
          const SizedBox(height: 24),
        ],
        if (pastBookedEvents.isNotEmpty) ...[
          _buildSectionHeader('Past Events', pastBookedEvents.length),
          const SizedBox(height: 8),
          ...pastBookedEvents.map(
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
}
