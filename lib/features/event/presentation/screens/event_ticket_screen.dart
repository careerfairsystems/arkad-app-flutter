import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../view_models/event_view_model.dart';

class EventTicketScreen extends StatefulWidget {
  final int eventId;

  const EventTicketScreen({super.key, required this.eventId});

  @override
  State<EventTicketScreen> createState() => _EventTicketScreenState();
}

class _EventTicketScreenState extends State<EventTicketScreen> {
  String? _ticketUuid;
  bool _isLoadingTicket = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEventAndTicket();
    });
  }

  Future<void> _loadEventAndTicket() async {
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);

    // Load event details if not already loaded
    await eventViewModel.getEventById(widget.eventId);

    // Load ticket
    await _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() => _isLoadingTicket = true);

    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    final ticket = await eventViewModel.getEventTicket(widget.eventId);

    setState(() {
      _ticketUuid = ticket;
      _isLoadingTicket = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        final event = viewModel.selectedEvent;

        return Scaffold(
          appBar: AppBar(
            title: Text(event?.title ?? 'Event Ticket'),
            backgroundColor: ArkadColors.arkadTurkos,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: _buildBody(event, viewModel),
        );
      },
    );
  }

  Widget _buildBody(Event? event, EventViewModel viewModel) {
    if (viewModel.isLoading && event == null) {
      return _buildLoadingState();
    }

    if (viewModel.error != null && event == null) {
      return _buildErrorState(viewModel);
    }

    if (event == null) {
      return _buildNotFoundState();
    }

    return _buildTicketContent(event);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading event details...'),
        ],
      ),
    );
  }

  Widget _buildErrorState(EventViewModel viewModel) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'Error Loading Event',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error?.userMessage ?? 'An unknown error occurred',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            ArkadButton(
              text: 'Try Again',
              onPressed: () => _loadEventAndTicket(),
              variant: ArkadButtonVariant.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Event Not Found',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'The requested event could not be found.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketContent(Event event) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Ticket Header
          _buildTicketHeader(event),
          const SizedBox(height: 32),

          // QR Code Section
          _buildQRCodeSection(),
          const SizedBox(height: 32),

          // Instructions
          _buildInstructions(),
        ],
      ),
    );
  }

  Widget _buildTicketHeader(Event event) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ArkadColors.arkadTurkos,
            ArkadColors.arkadTurkos.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            'Event Ticket',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQRCodeSection() {
    if (_isLoadingTicket) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 12),
              Text('Loading ticket...'),
            ],
          ),
        ),
      );
    }

    if (_ticketUuid == null) {
      return Container(
        width: double.infinity,
        height: 250,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: ArkadColors.lightRed),
            const SizedBox(height: 8),
            const Text(
              'Failed to load ticket',
              style: TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _loadTicket, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Make QR code take most of the available width, with some padding
          final qrSize = (constraints.maxWidth - 40).clamp(200.0, 300.0);

          return Column(
            children: [
              Center(
                child: QrImageView(
                  data: _ticketUuid!,
                  version: QrVersions.auto,
                  size: qrSize,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Show this QR code at the event',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: ArkadColors.arkadTurkos,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ArkadColors.arkadNavy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '• Present this QR code at the event entrance\n',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
