import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/company.dart';
import '../view_models/company_view_model.dart';
import '../widgets/advanced_filters_modal.dart';
import '../widgets/company_list.dart';
import '../widgets/company_quick_filters.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  late final TextEditingController _searchController;

  CompanyFilter _currentFilter = CompanyFilter(
    degrees: [],
    competences: [],
    positions: [],
    industries: [],
  );

  StreamSubscription? _logoutSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _subscribeToLogoutEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyViewModel = Provider.of<CompanyViewModel>(
        context,
        listen: false,
      );
      companyViewModel.getCompaniesCommand.reset();
      _loadCompanies();
    });
  }

  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _clearUIState();
    });
  }

  void _clearUIState() {
    if (mounted) {
      setState(() {
        _searchController.clear();
        _currentFilter = CompanyFilter(
          degrees: [],
          competences: [],
          positions: [],
          industries: [],
        );
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
          appBar: AppBar(title: const Text('Companies')),
          body: Column(
            children: [
              _buildSearchBar(),
              CompanyQuickFilters(
                hasStudentSessions: _currentFilter.hasStudentSessions,
                selectedPositions: _currentFilter.positions.toSet(),
                onStudentSessionsChanged: _onStudentSessionsChanged,
                onPositionToggled: _onPositionToggled,
                onAdvancedFiltersPressed: _showAdvancedFilters,
                onClearAllPressed: _clearAllFilters,
                totalActiveFilters: _getTotalActiveFilters(),
              ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Consumer<CompanyViewModel>(
        builder: (context, viewModel, child) {
          return TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search companies...',
              prefixIcon: viewModel.isSearching 
                ? Padding(
                    padding: const EdgeInsets.all(14),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: ArkadColors.arkadTurkos,
                      ),
                    ),
                  )
                : const Icon(Icons.search_rounded),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: ArkadColors.arkadTurkos, width: 2),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                      )
                      : null,
            ),
            onChanged: _onSearchChanged,
          );
        },
      ),
    );
  }

  Widget _buildResultsCount(CompanyViewModel viewModel) {
    final hasActiveFilters = _hasAnyFilters();
    final hasSearchQuery = _searchController.text.isNotEmpty;

    if (!hasActiveFilters && !hasSearchQuery) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 16,
            color: ArkadColors.arkadTurkos,
          ),
          const SizedBox(width: 6),
          Text(
            'Showing ${viewModel.companies.length} of ${viewModel.allCompanies.length} companies',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(CompanyViewModel viewModel) {
    final hasFiltersOrSearch =
        _hasAnyFilters() || _searchController.text.isNotEmpty;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                hasFiltersOrSearch
                    ? Icons.search_off_rounded
                    : Icons.business_rounded,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              viewModel.allCompanies.isEmpty
                  ? 'No companies available'
                  : 'No companies match your criteria',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (hasFiltersOrSearch) ...[
              const SizedBox(height: 12),
              Text(
                'Try adjusting your search or filters to find more companies',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ArkadButton(
                text: 'Clear All Filters',
                onPressed: _clearAllFilters,
                icon: Icons.filter_alt_off_rounded,
                variant: ArkadButtonVariant.secondary,
              ),
            ],
          ],
        ),
      ),
    );
  }

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

  void _showAdvancedFilters() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.9,
            child: AdvancedFiltersModal(
              initialFilter: _currentFilter,
              onFiltersApplied: (filter) {
                setState(() {
                  _currentFilter = filter;
                });
                _applyFilters();
              },
            ),
          ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _currentFilter = CompanyFilter(
        degrees: [],
        competences: [],
        positions: [],
        industries: [],
      );
    });
    _applyFilters();
  }

  void _applyFilters() {
    final viewModel = Provider.of<CompanyViewModel>(context, listen: false);
    viewModel.searchAndFilterCompanies(_searchController.text, _currentFilter);
  }

  bool _hasAnyFilters() => _currentFilter.hasActiveFilters;

  int _getTotalActiveFilters() {
    return _currentFilter.degrees.length +
        _currentFilter.competences.length +
        _currentFilter.positions.length +
        _currentFilter.industries.length +
        (_currentFilter.hasStudentSessions ? 1 : 0);
  }

  void _onStudentSessionsChanged(bool value) {
    setState(() {
      _currentFilter = _currentFilter.copyWith(hasStudentSessions: value);
    });
    _applyFilters();
  }

  void _onPositionToggled(String position) {
    setState(() {
      final positions = _currentFilter.positions.toSet();
      if (positions.contains(position)) {
        positions.remove(position);
      } else {
        positions.add(position);
      }
      _currentFilter = _currentFilter.copyWith(positions: positions.toList());
    });
    _applyFilters();
  }

  void _onCompanyTap(Company company) {
    context.push('/companies/detail/${company.id}');
  }
}
