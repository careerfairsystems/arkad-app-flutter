import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/widgets/company_logo_widget.dart';

/// Company information card displayed on map when a marker is selected
///
/// Shows company logo, name, industry, and provides navigation to details.
class CompanyInfoCard extends StatelessWidget {
  const CompanyInfoCard({
    super.key,
    required this.company,
    required this.onClose,
    required this.featureModelId,
  });

  final Company company;
  final VoidCallback onClose;
  final int featureModelId;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: ArkadColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company logo or placeholder
                _buildCompanyLogo(),
                const SizedBox(width: 16),

                // Company name and industry
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: ArkadColors.arkadNavy,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'MyriadProCondensed',
                        ),
                      ),
                      if (company.industries.isNotEmpty)
                        Text(
                          company.industries.first,
                          style: const TextStyle(
                            color: ArkadColors.gray,
                            fontSize: 14,
                            fontFamily: 'MyriadProCondensed',
                          ),
                        ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  color: ArkadColors.arkadNavy,
                  onPressed: onClose,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/companies/detail/${company.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArkadColors.arkadTurkos,
                      foregroundColor: ArkadColors.white,
                    ),
                    child: const Text('View Details'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      context.push('/navigate/${company.id}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArkadColors.arkadGreen,
                      foregroundColor: ArkadColors.white,
                    ),
                    child: const Text('Navigate to'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Feature model ID (muted text)
            Text(
              'Feature Model: $featureModelId',
              style: const TextStyle(
                color: ArkadColors.gray,
                fontSize: 12,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyLogo() {
    return CompanyLogoWidget(company: company);
  }
}
