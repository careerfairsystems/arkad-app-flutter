import 'package:arkad/config/theme_config.dart';
import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';

import 'package:flutter/material.dart';

class StudentSessionsScreen extends StatelessWidget {
  StudentSessionsScreen({super.key});

  // Dummy data for companies with sessions
  //List<Company> _companies = []
  final List<String> companiesWithSessions = ['Volvo', 'Scania', 'Ericsson'];
  final List<String> companiesWithSessionsIcons = [];

  //fångar upp alla företag med sessions
  // try {
  //     final companies = await _companyService.getAllCompanies();
  //     setState(() {
  //       _companies = companies;
  //       _applyFilters();
  //       _isLoading = false;
  //     });
  //   } catch (e) {
  //     setState(() {
  //       _isLoading = false;
  //       _hasError = true;
  //     });
  //   }

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


  // @override
  // Widget build(BuildContext context) {
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('Student Sessions')),
  //     body: Center(
  //       child: Column(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           const Icon(Icons.people, size: 80),
  //           const SizedBox(height: 16),
  //           const Text(
  //             'Student Sessions',
  //             style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
  //           ),
  //           const SizedBox(height: 16),
  //           Text(
  //             'View and manage your booked sessions',
  //             style: TextStyle(fontSize: 16, color: Colors.grey[600]),
  //           ),
  //           const SizedBox(height: 32),
  //           Padding(
  //             padding: const EdgeInsets.symmetric(horizontal: 24),
  //             child: ListView.builder(
  //               shrinkWrap: true,
  //               physics: const NeverScrollableScrollPhysics(),
  //               itemCount: 3,
  //               itemBuilder: (context, index) {
  //                 return Card(
  //                   margin: const EdgeInsets.only(bottom: 16),
  //                   child: ListTile(
  //                     leading: CircleAvatar(child: Icon(Icons.calendar_today)),
  //                     title: Text('Session with Company ${index + 1}'),
  //                     subtitle: Text('Date: Nov ${index + 10}, 2023'),
  //                     trailing: const Icon(Icons.chevron_right),
  //                   ),
  //                 );
  //               },
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }
//}
