import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../view_models/event_view_model.dart';
import 'event_attendees_screen.dart';

class EventAttendeesWrapper extends StatefulWidget {
  final int eventId;

  const EventAttendeesWrapper({super.key, required this.eventId});

  @override
  State<EventAttendeesWrapper> createState() => _EventAttendeesWrapperState();
}

class _EventAttendeesWrapperState extends State<EventAttendeesWrapper> {
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
        if (viewModel.isLoading && viewModel.selectedEvent == null) {
          return _buildLoadingState();
        }

        if (viewModel.error != null && viewModel.selectedEvent == null) {
          return _buildErrorState(viewModel);
        }

        if (viewModel.selectedEvent == null) {
          return _buildNotFoundState();
        }

        return EventAttendeesScreen(event: viewModel.selectedEvent!);
      },
    );
  }

  Widget _buildLoadingState() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading...'),
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ArkadColors.arkadTurkos),
            SizedBox(height: 16),
            Text('Loading event details...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: Colors.white,
      ),
      body: Center(
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
      appBar: AppBar(
        title: const Text('Event Not Found'),
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.event_busy,
                size: 64,
                color: ArkadColors.lightRed,
              ),
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
                text: 'Back',
                onPressed: () => context.pop(),
                icon: Icons.arrow_back,
                variant: ArkadButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
