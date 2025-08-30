import 'package:arkad/shared/presentation/themes/arkad_theme.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import '../../services/service_locator.dart';

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
    _arkadApi = serviceLocator<ArkadApi>();
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ListView.builder(
                  itemCount: _companies.length,
                  itemBuilder: (context, index) {
                    final company = _companies[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          // TODO: Handle button press
                          print('Selected ${company.name}');
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: [
                                ArkadColors.arkadNavy,
                                ArkadColors.arkadTurkos,
                              ],
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
                              const Icon(
                                Icons.chevron_right,
                                color: ArkadColors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
