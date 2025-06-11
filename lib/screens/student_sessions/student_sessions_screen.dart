import 'package:arkad/config/theme_config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/company.dart';
import '../../services/student_sessions_service.dart';
import '../../utils/service_helper.dart';

class StudentSessionsScreen extends StatefulWidget {
  const StudentSessionsScreen({super.key});

  @override
  State<StudentSessionsScreen> createState() => _StudentSessionsScreen();
}

class _StudentSessionsScreen extends State<StudentSessionsScreen> {
  late final StudentSessionsService _studentSessionsService;

  List<Company> _companies = [];

  @override
  void initState() {
    super.initState();
    _studentSessionsService =
        ServiceHelper.getService<StudentSessionsService>();
    _loadCompanies();
  }

  /*
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  */

  Future<void> _loadCompanies() async {
    setState(() {
      //_isLoading = true;
      //_hasError = false;
    });

    try {
      final companies =
          (await _studentSessionsService.getAllCompanies())
              .where((i) => i.daysWithStudentsession > 0)
              .toList();
      setState(() {
        _companies = companies;
        //_applyFilters();
        //_isLoading = false;
      });
    } catch (e) {
      setState(() {
        //_isLoading = false;
        //_hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Sessions')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 80),
            const SizedBox(height: 16),
            const Text(
              'Student Sessions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'View and manage your booked sessions',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: ListTile(
                      leading: CircleAvatar(child: Icon(Icons.calendar_today)),
                      title: Text('Session with Company ${index + 1}'),
                      subtitle: Text('Date: Nov ${index + 10}, 2023'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push('/sessions/form/${index + 1}'),
                    ),
                  );
                },
              ),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  // TODO: Handle button press
                  print('Selected $company');
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
                          company.name,
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
