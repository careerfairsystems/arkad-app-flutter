import 'package:arkad/utils/sentry_utils.dart';
import 'package:flutter/material.dart';

import '../../models/company.dart';
import '../../services/company_service.dart';
import '../../utils/service_helper.dart';
import '../../widgets/filter_dropdown.dart';
import '../../widgets/filter_dropdown_controller.dart';
import '../../widgets/loading_indicator.dart';
import 'company_detail_screen.dart';
import 'filter_options.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  late final CompanyService _companyService;
  List<Company> _companies = [];
  List<Company> _filteredCompanies = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _searchQuery = '';
  TextEditingController _searchController = TextEditingController();
  bool _showFilters = false;

  // Filter dropdown controller
  final FilterDropdownController _dropdownController =
      FilterDropdownController();

  // Selected filter options
  Set<String> _selectedDegrees = {};
  Set<String> _selectedCompetences = {};
  Set<String> _selectedPositions = {};
  Set<String> _selectedIndustries = {};
  bool _hasStudentSessions = false;

  @override
  void initState() {
    super.initState();
    _companyService = ServiceHelper.getService<CompanyService>();
    _loadCompanies();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    } catch (e, stackTrace) {
      SentryUtils.captureException(e, stackTrace: stackTrace);
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty &&
        _selectedDegrees.isEmpty &&
        _selectedCompetences.isEmpty &&
        _selectedPositions.isEmpty &&
        _selectedIndustries.isEmpty &&
        !_hasStudentSessions) {
      setState(() {
        _filteredCompanies = List.from(_companies);
      });
      return;
    }

    // First filter by search query if present
    List<Company> searchResults =
        _searchQuery.isEmpty
            ? List.from(_companies)
            : _companyService.searchCompanies(_searchQuery);

    // Then apply additional filters
    final filteredResults = _companyService.filterCompanies(
      companies: searchResults,
      degrees: _selectedDegrees.isNotEmpty ? _selectedDegrees.toList() : null,
      competences:
          _selectedCompetences.isNotEmpty
              ? _selectedCompetences.toList()
              : null,
      positions:
          _selectedPositions.isNotEmpty ? _selectedPositions.toList() : null,
      industries:
          _selectedIndustries.isNotEmpty ? _selectedIndustries.toList() : null,
      hasStudentSessions: _hasStudentSessions ? true : null,
    );

    setState(() {
      _filteredCompanies = filteredResults;
    });
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      // Collapse all dropdowns when hiding filters
      if (!_showFilters) {
        _dropdownController.collapseAll();
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDegrees = {};
      _selectedCompetences = {};
      _selectedPositions = {};
      _selectedIndustries = {};
      _hasStudentSessions = false;
      _applyFilters();
    });
  }

  void _updateDegreesFilter(Set<String> selected) {
    setState(() {
      _selectedDegrees = selected;
      _applyFilters();
    });
  }

  void _updateCompetencesFilter(Set<String> selected) {
    setState(() {
      _selectedCompetences = selected;
      _applyFilters();
    });
  }

  void _updatePositionsFilter(Set<String> selected) {
    setState(() {
      _selectedPositions = selected;
      _applyFilters();
    });
  }

  void _updateIndustriesFilter(Set<String> selected) {
    setState(() {
      _selectedIndustries = selected;
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _toggleFilters,
            tooltip: 'Filter companies',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
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
                suffixIcon:
                    _searchQuery.isNotEmpty
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

          // Filter section (collapsible and scrollable)
          AnimatedCrossFade(
            firstChild: _buildScrollableFilterSection(),
            secondChild: const SizedBox.shrink(),
            crossFadeState:
                _showFilters
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 300),
          ),

          // Companies list
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildScrollableFilterSection() {
    // Calculate available height for filter section (approximately 50% of screen height)
    final double maxFilterHeight = MediaQuery.of(context).size.height * 0.5;

    return Container(
      constraints: BoxConstraints(maxHeight: maxFilterHeight),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Card(
        margin: EdgeInsets.zero,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildFilterContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterContent() {
    // Count total active filters for the badge
    int totalActiveFilters =
        _selectedDegrees.length +
        _selectedCompetences.length +
        _selectedPositions.length +
        _selectedIndustries.length +
        (_hasStudentSessions ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                if (totalActiveFilters > 0)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$totalActiveFilters',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            Row(
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                  onPressed: _toggleFilters,
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _clearAllFilters,
                  child: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
        const Divider(),

        // Student Session filter - kept as switch
        Row(
          children: [
            Switch(
              value: _hasStudentSessions,
              onChanged: (value) {
                setState(() {
                  _hasStudentSessions = value;
                  _applyFilters();
                });
              },
            ),
            const Text('Has Student Sessions'),
          ],
        ),
        const Divider(),

        // Degrees dropdown
        FilterDropdown<String>(
          id: 'degrees',
          title: 'Degrees',
          options: FilterOptions.degrees,
          selectedValues: _selectedDegrees,
          onSelectionChanged: _updateDegreesFilter,
          displayStringForOption: (option) => option,
          controller: _dropdownController,
        ),
        const Divider(),

        // Positions dropdown
        FilterDropdown<String>(
          id: 'positions',
          title: 'Positions',
          options: FilterOptions.positions,
          selectedValues: _selectedPositions,
          onSelectionChanged: _updatePositionsFilter,
          displayStringForOption: (option) => option,
          controller: _dropdownController,
        ),
        const Divider(),

        // Industries dropdown
        FilterDropdown<String>(
          id: 'industries',
          title: 'Industries',
          options: FilterOptions.industries,
          selectedValues: _selectedIndustries,
          onSelectionChanged: _updateIndustriesFilter,
          displayStringForOption: (option) => option,
          controller: _dropdownController,
        ),
        const Divider(),

        // Competences dropdown
        FilterDropdown<String>(
          id: 'competences',
          title: 'Competences',
          options: FilterOptions.competences,
          selectedValues: _selectedCompetences,
          onSelectionChanged: _updateCompetencesFilter,
          displayStringForOption: (option) => option,
          controller: _dropdownController,
        ),
        // Padding at the bottom to ensure space after the last dropdown
        const SizedBox(height: 8),
      ],
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
                  : 'No companies match your criteria',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            if (_hasStudentSessions ||
                _selectedDegrees.isNotEmpty ||
                _selectedCompetences.isNotEmpty ||
                _selectedPositions.isNotEmpty ||
                _selectedIndustries.isNotEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear Filters'),
                onPressed: _clearAllFilters,
              ),
            ],
          ],
        ),
      );
    }

    // Display result count
    int totalFilters =
        _selectedDegrees.length +
        _selectedCompetences.length +
        _selectedPositions.length +
        _selectedIndustries.length +
        (_hasStudentSessions ? 1 : 0);

    return Column(
      children: [
        if (totalFilters > 0 || _searchQuery.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Text(
                  'Showing ${_filteredCompanies.length} of ${_companies.length} companies',
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: .6),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadCompanies(),
            child: ListView.builder(
              itemCount: _filteredCompanies.length,
              itemBuilder: (context, index) {
                final company = _filteredCompanies[index];
                return _buildCompanyCard(company);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading:
            company.fullLogoUrl != null
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
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              company.industriesString,
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
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
}
