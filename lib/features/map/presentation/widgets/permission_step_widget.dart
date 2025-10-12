import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/permission_request.dart';

class PermissionStepWidget extends StatelessWidget {
  const PermissionStepWidget({
    required this.step,
    required this.onRequestPermission,
    required this.onOpenSettings,
    required this.isLoading,
    super.key,
  });

  final PermissionRequest step;
  final VoidCallback onRequestPermission;
  final VoidCallback onOpenSettings;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final needsSettings = step.status == PermissionStatus.permanentlyDenied;
    final buttonText = needsSettings ? 'Open Settings' : 'Grant Permission';
    final buttonAction = needsSettings ? onOpenSettings : onRequestPermission;

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Icon area (top)
        Expanded(
          flex: 2,
          child: Center(
            child: Image.asset(
              step.iconPath,
              height: 200,
              width: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback icon if image not found
                return const Icon(
                  Icons.location_on,
                  size: 80,
                  color: ArkadColors.arkadTurkos,
                );
              },
            ),
          ),
        ),

        // Content area (bottom)
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title and description
                Column(
                  children: [
                    Text(
                      step.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      step.description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    // Warning for permanently denied
                    if (needsSettings)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Please enable this permission in your device settings.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: ArkadColors.lightRed,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),

                // Button
                ArkadButton(
                  text: buttonText,
                  onPressed: isLoading ? null : buttonAction,
                  isLoading: isLoading,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
