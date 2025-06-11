import 'package:arkad/config/theme_config.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../utils/service_helper.dart';

class StudentSessionsScreen extends StatefulWidget {
  const StudentSessionsScreen({super.key});

  @override
  State<StudentSessionsScreen> createState() => _StudentSessionsScreen();
}

class _StudentSessionsScreen extends State<StudentSessionsScreen> {
  late final ArkadApi _arkadApi;

  List<CompanyOut> _companies = [];

  @override
  void initState() {
    super.initState();
    _arkadApi = ServiceHelper.getService<ArkadApi>();
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
      final response =
          await _arkadApi.getCompaniesApi().companiesApiGetCompanies();
      final companies = response.data?.toList() ?? [];
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
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: ListView.builder(
          itemCount: _companies.length + 1, // +1 for header
          itemBuilder: (context, index) {
            if (index == 0) {
              // Header content
              return Column(
                children: [
                  const SizedBox(height: 40),
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
                ],
              );
            }

            // Company cards
            final company = _companies[index - 1];
            return Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  context.push('/sessions/form/${company.id}');
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
