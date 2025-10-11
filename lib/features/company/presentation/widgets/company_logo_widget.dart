import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/company.dart';

/// Widget that displays a company logo from assets
///
/// Calls company.getCompanyLogo() to load the logo asset.
/// Falls back to a default icon if null is returned.
class CompanyLogoWidget extends StatelessWidget {
  const CompanyLogoWidget({
    super.key,
    required this.company,
    this.size = 48,
    this.borderRadius = 8,
  });

  final Company company;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: ArkadColors.arkadLightNavy,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: FutureBuilder<bool>(
        future: _loadLogo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ArkadColors.arkadTurkos,
                ),
              ),
            );
          }

          final logoExists = snapshot.data ?? false;

          if (logoExists) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: Image.asset(
                'assets/images/companies/${company.id}.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildDefaultIcon(),
              ),
            );
          }

          // Fallback to default icon if logo is null or doesn't exist
          return _buildDefaultIcon();
        },
      ),
    );
  }

  Widget _buildDefaultIcon() {
    return Icon(
      Icons.business,
      color: ArkadColors.arkadTurkos,
      size: size * 0.5,
    );
  }

  /// Calls getCompanyLogo() and returns true if logo exists, false otherwise
  Future<bool> _loadLogo() async {
    final logo = await company.getCompanyLogo();
    // If getCompanyLogo returns null, we return false to show the default icon
    return logo != null;
  }
}
