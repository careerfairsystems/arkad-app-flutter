import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';

class ScanEventScreen extends StatefulWidget {
  const ScanEventScreen({super.key});

  @override
  State<ScanEventScreen> createState() => _ScanEventScreenState();
}

class _ScanEventScreenState extends State<ScanEventScreen> {
  MobileScannerController cameraController = MobileScannerController();
  String? scannedData;
  bool isScanning = true;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          scannedData = barcode.rawValue;
          isScanning = false;
        });
        break;
      }
    }
  }

  void _scanAgain() {
    setState(() {
      scannedData = null;
      isScanning = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Event QR Code',
          style: TextStyle(
            fontFamily: 'MyriadProCondensed',
            fontWeight: FontWeight.w600,
            color: ArkadColors.arkadNavy,
          ),
        ),
        backgroundColor: ArkadColors.white,
        iconTheme: const IconThemeData(color: ArkadColors.arkadNavy),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Scanner or result display
          Expanded(
            flex: 3,
            child: scannedData != null ? _buildResultCard() : _buildScanner(),
          ),

          // Action buttons
          if (scannedData != null) ...[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ArkadButton(
                    text: 'Scan Again',
                    onPressed: _scanAgain,
                    variant: ArkadButtonVariant.secondary,
                    fullWidth: true,
                    icon: Icons.qr_code_scanner,
                  ),
                  const SizedBox(height: 12),
                  ArkadButton(
                    text: 'Consume ticket',
                    onPressed: () => Navigator.of(context).pop(),
                    variant: ArkadButtonVariant.primary,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
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
                      width: 1,
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
          elevation: 4,
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
                        Icons.check_circle,
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
                        color: ArkadColors.arkadNavy,
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
                    color: ArkadColors.arkadTurkos.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ArkadColors.arkadTurkos.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    scannedData ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      color: ArkadColors.arkadNavy,
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
}
