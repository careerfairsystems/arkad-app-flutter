import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../../../shared/presentation/widgets/filters/filter_dropdown.dart';
import '../../../../shared/presentation/widgets/filters/filter_dropdown_controller.dart';
import '../../domain/entities/company.dart';
import '../view_models/company_view_model.dart';
import '../widgets/company_list.dart';
import '../widgets/filter_options.dart';

/// Modern companies screen using clean architecture
class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  late final TextEditingController _searchController;
  late final FilterDropdownController _dropdownController;
  bool _showFilters = false;

  // Current filter state
  Set<String> _selectedDegrees = {};
  Set<String> _selectedCompetences = {};
  Set<String> _selectedPositions = {};
  Set<String> _selectedIndustries = {};
  bool _hasStudentSessions = false;

  // Stream subscription for logout events
  StreamSubscription? _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _dropdownController = FilterDropdownController();
    
    // Subscribe to logout events for cleanup
    _subscribeToLogoutEvents();
    
    // Load companies on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCompanies();
    });
  }

  /// Subscribe to logout events for cleanup
  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _clearUIState();
    });
  }

  /// Clear UI state when user logs out
  void _clearUIState() {
    if (mounted) {
      setState(() {
        // Clear search
        _searchController.clear();
        
        // Reset filter states
        _selectedDegrees.clear();
        _selectedCompetences.clear();
        _selectedPositions.clear();
        _selectedIndustries.clear();
        _hasStudentSessions = false;
        
        // Hide filters
        _showFilters = false;
        _dropdownController.collapseAll();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _logoutSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CompanyViewModel>(
      builder: (context, viewModel, child) {
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
              _buildSearchBar(),
              _buildFiltersSection(viewModel),
              _buildResultsCount(viewModel),
              Expanded(
                child: CompanyList(
                  command: viewModel.getCompaniesCommand,
                  companies: viewModel.companies,
                  onCompanyTap: _onCompanyTap,
                  onRefresh: () => _loadCompanies(forceRefresh: true),
                  emptyStateWidget: _buildEmptyState(viewModel),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search companies...',
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearSearch,
                )
              : null,
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }

  Widget _buildFiltersSection(CompanyViewModel viewModel) {
    return AnimatedCrossFade(
      firstChild: _buildScrollableFilterSection(),
      secondChild: const SizedBox.shrink(),
      crossFadeState: _showFilters 
          ? CrossFadeState.showFirst 
          : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 300),
    );
  }

  Widget _buildScrollableFilterSection() {
    final maxFilterHeight = MediaQuery.of(context).size.height * 0.5;

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
    final totalActiveFilters = _selectedDegrees.length +
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                ArkadButton(
                  text: 'Clear All',
                  onPressed: _clearAllFilters,
                  variant: ArkadButtonVariant.secondary,
                ),
              ],
            ),
          ],
        ),
        const Divider(),

        // Student Session filter
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

        // Filter dropdowns
        ...[ 
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
          FilterDropdown<String>(
            id: 'competences',
            title: 'Competences',
            options: FilterOptions.competences,
            selectedValues: _selectedCompetences,
            onSelectionChanged: _updateCompetencesFilter,
            displayStringForOption: (option) => option,
            controller: _dropdownController,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildResultsCount(CompanyViewModel viewModel) {
    final hasActiveFilters = _hasAnyFilters();
    final hasSearchQuery = _searchController.text.isNotEmpty;
    
    if (!hasActiveFilters && !hasSearchQuery) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        'Showing ${viewModel.companies.length} of ${viewModel.allCompanies.length} companies',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildEmptyState(CompanyViewModel viewModel) {
    final hasFiltersOrSearch = _hasAnyFilters() || _searchController.text.isNotEmpty;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            viewModel.allCompanies.isEmpty
                ? 'No companies available'
                : 'No companies match your criteria',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          if (hasFiltersOrSearch) ...[
            const SizedBox(height: 16),
            ArkadButton(
              text: 'Clear Filters',
              onPressed: _clearAllFilters,
              icon: Icons.filter_alt_off,
              variant: ArkadButtonVariant.secondary,
            ),
          ],
        ],
      ),
    );
  }

  // Event handlers
  Future<void> _loadCompanies({bool forceRefresh = false}) async {
    final viewModel = Provider.of<CompanyViewModel>(context, listen: false);
    await viewModel.loadCompanies(forceRefresh: forceRefresh);
  }

  void _onSearchChanged(String value) {
    final viewModel = Provider.of<CompanyViewModel>(context, listen: false);
    viewModel.searchCompanies(value);
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    final viewModel = Provider.of<CompanyViewModel>(context, listen: false);
    viewModel.clearSearch();
  }

  void _toggleFilters() {
    setState(() {
      _showFilters = !_showFilters;
      if (!_showFilters) {
        _dropdownController.collapseAll();
      }
    });
  }

  void _clearAllFilters() {
    setState(() {
      _selectedDegrees.clear();
      _selectedCompetences.clear();
      _selectedPositions.clear();
      _selectedIndustries.clear();
      _hasStudentSessions = false;
    });
    _applyFilters();
  }

  void _applyFilters() {
    final viewModel = Provider.of<CompanyViewModel>(context, listen: false);
    final filter = CompanyFilter(
      degrees: _selectedDegrees.toList(),
      competences: _selectedCompetences.toList(),
      positions: _selectedPositions.toList(),
      industries: _selectedIndustries.toList(),
      hasStudentSessions: _hasStudentSessions,
    );
    
    viewModel.searchAndFilterCompanies(_searchController.text, filter);
  }

  bool _hasAnyFilters() =>
      _selectedDegrees.isNotEmpty ||
      _selectedCompetences.isNotEmpty ||
      _selectedPositions.isNotEmpty ||
      _selectedIndustries.isNotEmpty ||
      _hasStudentSessions;

  // Filter update handlers
  void _updateDegreesFilter(Set<String> selected) {
    setState(() => _selectedDegrees = selected);
    _applyFilters();
  }

  void _updateCompetencesFilter(Set<String> selected) {
    setState(() => _selectedCompetences = selected);
    _applyFilters();
  }

  void _updatePositionsFilter(Set<String> selected) {
    setState(() => _selectedPositions = selected);
    _applyFilters();
  }

  void _updateIndustriesFilter(Set<String> selected) {
    setState(() => _selectedIndustries = selected);
    _applyFilters();
  }

  void _onCompanyTap(Company company) {
    // For now, just navigate with the company ID
    // TODO: Update navigation to work with domain entities properly
    context.push('/companies/detail/${company.id}');
  }
}