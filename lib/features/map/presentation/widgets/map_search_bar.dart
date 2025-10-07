import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

/// Search bar widget for map screen
///
/// Displays a rounded search bar with icon and text.
/// Tappable to trigger search functionality.
class MapSearchBar extends StatelessWidget {
  const MapSearchBar({
    super.key,
    required this.onTap,
    this.displayText,
    this.placeholderText = 'Search companies',
  });

  final VoidCallback onTap;
  final String? displayText;
  final String placeholderText;

  @override
  Widget build(BuildContext context) {
    final hasSelection = displayText != null && displayText!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: ArkadColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ArkadColors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            const Icon(Icons.search, color: ArkadColors.arkadNavy, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                hasSelection ? displayText! : placeholderText,
                style: TextStyle(
                  color: hasSelection ? ArkadColors.arkadNavy : ArkadColors.gray,
                  fontSize: 16,
                  fontFamily: 'MyriadProCondensed',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
