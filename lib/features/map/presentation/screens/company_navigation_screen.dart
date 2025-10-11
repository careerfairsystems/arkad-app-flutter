import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

/// Screen for navigating to a company location
class CompanyNavigationScreen extends StatelessWidget {
  const CompanyNavigationScreen({super.key, required this.companyId});

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
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 80, color: ArkadColors.arkadTurkos),
            SizedBox(height: 32),
            Text(
              'Coming Soon',
              style: TextStyle(
                color: ArkadColors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
            SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 48.0),
              child: Text(
                'Indoor navigation to company booths will be available soon',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ArkadColors.gray,
                  fontSize: 16,
                  fontFamily: 'MyriadProCondensed',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
