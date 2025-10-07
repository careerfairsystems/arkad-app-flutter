import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/ticket_verification_result.dart';
import '../view_models/event_view_model.dart';

class ScanEventScreen extends StatefulWidget {
  final int eventId;

  const ScanEventScreen({super.key, required this.eventId});

  @override
  State<ScanEventScreen> createState() => _ScanEventScreenState();
}

class _ScanEventScreenState extends State<ScanEventScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedData;
  bool isScanning = true;
  bool isProcessingTicket = false;
  TicketVerificationResult? ticketResult;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning || isProcessingTicket) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          scannedData = barcode.rawValue;
          isScanning = false;
        });
        _processTicket(barcode.rawValue!);
        break;
      }
    }
  }

  Future<void> _processTicket(String uuid) async {
    if (isProcessingTicket) return;

    setState(() {
      isProcessingTicket = true;
    });

    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    final result = await eventViewModel.useTicket(uuid, widget.eventId);

    result.when(
      success: (ticket) {
        setState(() {
          ticketResult = ticket;
          isProcessingTicket = false;
        });
      },
      failure: (error) {
        setState(() {
          isProcessingTicket = false;
          ticketResult = null; // Clear stale success state
        });
        // Error will be shown through the EventViewModel's error state
      },
    );
  }

  void _scanAgain() {
    // Clear EventViewModel error state
    final eventViewModel = Provider.of<EventViewModel>(context, listen: false);
    eventViewModel.clearError();

    setState(() {
      scannedData = null;
      isScanning = true;
      isProcessingTicket = false;
      ticketResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, eventViewModel, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Scan Event QR Code',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body: Column(
            children: [
              // Scanner or result display
              Expanded(flex: 3, child: _buildMainContent(eventViewModel)),

              // Action buttons
              if (scannedData != null && !isProcessingTicket) ...[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ArkadButton(
                        text: 'Scan Again',
                        onPressed: _scanAgain,
                        variant: ArkadButtonVariant.secondary,
                        fullWidth: true,
                        icon: Icons.qr_code_scanner_rounded,
                      ),
                      if (ticketResult != null) ...[
                        const SizedBox(height: 12),
                        ArkadButton(
                          text: 'Close',
                          onPressed: () => context.pop(),
                          fullWidth: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMainContent(EventViewModel eventViewModel) {
    if (scannedData == null) {
      return _buildScanner();
    } else if (isProcessingTicket) {
      return _buildLoadingCard();
    } else if (eventViewModel.error != null) {
      return _buildErrorCard(eventViewModel.error!);
    } else if (ticketResult != null) {
      return _buildTicketResultCard(ticketResult!);
    } else {
      return _buildResultCard();
    }
  }

  Widget _buildScanner() {
    return Container(
      decoration: const BoxDecoration(color: Colors.black),
      child: Stack(
        children: [
          MobileScanner(controller: cameraController, onDetect: _onDetect),

          // Scanning overlay
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
            ),
            child: Center(
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: ArkadColors.arkadTurkos, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: ArkadColors.arkadTurkos.withValues(alpha: 0.5),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          // Instructions
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: ArkadColors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Position the QR code within the frame to scan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ArkadColors.arkadNavy,
                  fontFamily: 'MyriadProCondensed',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          color: ArkadColors.arkadLightNavy,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Success icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: ArkadColors.arkadGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Event details',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'MyriadProCondensed',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Scanned data
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    scannedData ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'MyriadProCondensed',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          color: ArkadColors.arkadLightNavy,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: ArkadColors.arkadTurkos),
                const SizedBox(height: 24),
                const Text(
                  'Processing ticket...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'MyriadProCondensed',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Verifying: ${scannedData ?? ''}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                    fontFamily: 'MyriadProCondensed',
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(error) {
    print("Error is: $error");

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          color: ArkadColors.arkadLightNavy,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error icon and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.errorContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.error_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Ticket Error',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'MyriadProCondensed',
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Error message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.errorContainer.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    error.userMessage,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontFamily: 'MyriadProCondensed',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketResultCard(TicketVerificationResult ticket) {
    final fullName = ticket.userInfo?.fullName ?? 'Unknown User';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Card(
          color: ArkadColors.arkadLightNavy,
          elevation: 4,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge and title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: ArkadColors.arkadGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ticket Consumed Successfully',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontFamily: 'MyriadProCondensed',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ArkadColors.arkadGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'CONSUMED',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                fontFamily: 'MyriadProCondensed',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // User information (only show if we have user info)
                if (ticket.userInfo != null) ...[
                  if (fullName != 'Unknown User') ...[
                    _buildTicketDetailRow('Name', fullName),
                    const SizedBox(height: 12),
                  ],

                  if (ticket.userInfo!.foodPreferences != null &&
                      ticket.userInfo!.foodPreferences!.isNotEmpty) ...[
                    _buildTicketDetailRow(
                      'Food Preferences',
                      ticket.userInfo!.foodPreferences!,
                    ),
                    const SizedBox(height: 12),
                  ],
                ],

                // Ticket details
                _buildTicketDetailRow('Ticket ID', ticket.uuid),
                const SizedBox(height: 12),
                _buildTicketDetailRow('Event ID', ticket.eventId.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetailRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: ArkadColors.arkadTurkos,
              fontFamily: 'MyriadProCondensed',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontFamily: 'MyriadProCondensed',
            ),
          ),
        ],
      ),
    );
  }
}
