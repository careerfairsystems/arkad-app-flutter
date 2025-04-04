import 'package:flutter/material.dart';
import '../../models/company.dart';
import '../../services/company_service.dart';
import 'company_detail_screen.dart';
import '../../widgets/loading_indicator.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({Key? key}) : super(key: key);

  @override
  _CompaniesScreenState createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  final CompanyService _companyService = CompanyService();
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final companies = await _companyService.getAllCompanies();
      setState(() {
        _companies = companies;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredCompanies = List.from(_companies);
    } else {
      _filteredCompanies = _companyService.searchCompanies(_searchQuery);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _applyFilters();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _applyFilters();
                });
              },
            ),
          ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: LoadingIndicator());
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Failed to load companies'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCompanies,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (_filteredCompanies.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _companies.isEmpty
                  ? 'No companies available'
                  : 'No companies match your search',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadCompanies(),
      child: ListView.builder(
        itemCount: _filteredCompanies.length,
        itemBuilder: (context, index) {
          final company = _filteredCompanies[index];
          return _buildCompanyCard(company);
        },
      ),
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: company.fullLogoUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  company.fullLogoUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[200],
                      child: const Icon(Icons.business, color: Colors.grey),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[200],
                child: const Icon(Icons.business, color: Colors.grey),
              ),
        title: Text(
          company.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              company.industriesString,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            if (company.locationsString.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      company.locationsString,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CompanyDetailScreen(company: company),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
