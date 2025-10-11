import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

/// Screen for navigating to a company location
class CompanyNavigationScreen extends StatelessWidget {
  const CompanyNavigationScreen({
    super.key,
    required this.companyId,
  });

  final int companyId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArkadColors.arkadNavy,
      appBar: AppBar(
        title: const Text('Navigate to Company'),
        backgroundColor: ArkadColors.arkadNavy,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.navigation,
              size: 64,
              color: ArkadColors.arkadTurkos,
            ),
            const SizedBox(height: 24),
            Text(
              'Navigation for Company ID: $companyId',
              style: const TextStyle(
                color: ArkadColors.white,
                fontSize: 18,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Navigation feature coming soon',
              style: TextStyle(
                color: ArkadColors.gray,
                fontSize: 14,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
