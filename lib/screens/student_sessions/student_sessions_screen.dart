import 'package:arkad/config/theme_config.dart';
import 'package:flutter/material.dart';

//import '../../models/company.dart';
//import '../../services/company_service.dart';
//import 'package:flutter/material.dart';

class StudentSessionsScreen extends StatelessWidget {
  const StudentSessionsScreen({super.key});

  static const List<String> companiesWithSessions = [
    'Volvo',
    'Scania',
    'Ericsson',
  ];
  static const List<String> companiesWithSessionsIcons = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Sessions')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: companiesWithSessions.length,
          itemBuilder: (context, index) {
            final companyName = companiesWithSessions[index];
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // TODO: Handle button press
                  print('Selected $companyName');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [ArkadColors.arkadNavy, ArkadColors.arkadTurkos],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.business,
                        color: ArkadColors.white,
                        size: 30,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'View sessions for $companyName',
                          style: const TextStyle(
                            color: ArkadColors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: ArkadColors.white),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
