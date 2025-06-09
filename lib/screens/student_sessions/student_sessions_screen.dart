import 'package:arkad/config/theme_config.dart';
import 'package:flutter/material.dart';

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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: _companies.length,
          itemBuilder: (context, index) {
            final company = _companies[index];
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
