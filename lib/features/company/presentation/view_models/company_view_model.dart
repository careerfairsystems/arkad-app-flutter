import 'package:flutter/foundation.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/company.dart';
import '../commands/filter_companies_command.dart';
import '../commands/get_companies_command.dart';
import '../commands/search_and_filter_companies_command.dart';
import '../commands/search_companies_command.dart';

/// ViewModel for managing company-related state and operations
class CompanyViewModel extends ChangeNotifier {
  CompanyViewModel({
    required GetCompaniesCommand getCompaniesCommand,
    required SearchCompaniesCommand searchCompaniesCommand,
    required FilterCompaniesCommand filterCompaniesCommand,
    required SearchAndFilterCompaniesCommand searchAndFilterCommand,
  }) : _getCompaniesCommand = getCompaniesCommand,
       _searchCompaniesCommand = searchCompaniesCommand,
       _filterCompaniesCommand = filterCompaniesCommand,
       _searchAndFilterCommand = searchAndFilterCommand {
    
    // Listen to command state changes
    _getCompaniesCommand.addListener(_onCommandChanged);
    _searchCompaniesCommand.addListener(_onCommandChanged);
    _filterCompaniesCommand.addListener(_onCommandChanged);
    _searchAndFilterCommand.addListener(_onCommandChanged);
  }

  final GetCompaniesCommand _getCompaniesCommand;
  final SearchCompaniesCommand _searchCompaniesCommand;
  final FilterCompaniesCommand _filterCompaniesCommand;
  final SearchAndFilterCompaniesCommand _searchAndFilterCommand;

  // Current state
  String _currentSearchQuery = '';
  CompanyFilter _currentFilter = const CompanyFilter();
  List<Company> _displayedCompanies = [];

  // Command getters (for direct access if needed)
  GetCompaniesCommand get getCompaniesCommand => _getCompaniesCommand;
  SearchCompaniesCommand get searchCompaniesCommand => _searchCompaniesCommand;
  FilterCompaniesCommand get filterCompaniesCommand => _filterCompaniesCommand;
  SearchAndFilterCompaniesCommand get searchAndFilterCommand => _searchAndFilterCommand;

  // State getters
  List<Company> get companies => _displayedCompanies;
  List<Company> get allCompanies => _getCompaniesCommand.result ?? [];
  String get currentSearchQuery => _currentSearchQuery;
  CompanyFilter get currentFilter => _currentFilter;
  
  bool get isLoading => 
      _getCompaniesCommand.isExecuting ||
      _searchCompaniesCommand.isExecuting ||
      _filterCompaniesCommand.isExecuting ||
      _searchAndFilterCommand.isExecuting;

  bool get hasError => 
      _getCompaniesCommand.hasError ||
      _searchCompaniesCommand.hasError ||
      _filterCompaniesCommand.hasError ||
      _searchAndFilterCommand.hasError;

  AppError? get error => 
      _getCompaniesCommand.error ??
      _searchCompaniesCommand.error ??
      _filterCompaniesCommand.error ??
      _searchAndFilterCommand.error;

  bool get hasCompanies => _displayedCompanies.isNotEmpty;
  bool get isInitialized => _getCompaniesCommand.result != null;

  /// Load all companies
  Future<void> loadCompanies({bool forceRefresh = false}) async {
    await _getCompaniesCommand.loadCompanies(forceRefresh: forceRefresh);
    _updateDisplayedCompanies();
  }

  /// Search companies by query
  Future<void> searchCompanies(String query) async {
    _currentSearchQuery = query;
    _updateDisplayedCompanies();
  }

  /// Filter companies by criteria
  Future<void> filterCompanies(CompanyFilter filter) async {
    _currentFilter = filter;
    _updateDisplayedCompanies();
  }

  /// Update search query and filter simultaneously
  Future<void> searchAndFilterCompanies(String query, CompanyFilter filter) async {
    _currentSearchQuery = query;
    _currentFilter = filter;
    _updateDisplayedCompanies();
  }

  /// Clear search query
  void clearSearch() {
    _currentSearchQuery = '';
    _updateDisplayedCompanies();
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilter = const CompanyFilter();
    _updateDisplayedCompanies();
  }

  /// Clear both search and filters
  void clearAll() {
    _currentSearchQuery = '';
    _currentFilter = const CompanyFilter();
    _updateDisplayedCompanies();
  }

  /// Get a specific company by ID
  Company? getCompanyById(int id) {
    try {
      return allCompanies.firstWhere((company) => company.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get available filter options from loaded companies
  List<String> getAvailableIndustries() {
    final industries = <String>{};
    for (final company in allCompanies) {
      industries.addAll(company.industries);
    }
    return industries.toList()..sort();
  }

  List<String> getAvailablePositions() {
    final positions = <String>{};
    for (final company in allCompanies) {
      positions.addAll(company.positions);
    }
    return positions.toList()..sort();
  }

  List<String> getAvailableCompetences() {
    final competences = <String>{};
    for (final company in allCompanies) {
      competences.addAll(company.desiredCompetences);
    }
    return competences.toList()..sort();
  }

  List<String> getAvailableDegrees() {
    final degrees = <String>{};
    for (final company in allCompanies) {
      degrees.addAll(company.desiredDegrees);
    }
    return degrees.toList()..sort();
  }

  /// Clear any errors
  void clearError() {
    _getCompaniesCommand.clearError();
    _searchCompaniesCommand.clearError();
    _filterCompaniesCommand.clearError();
    _searchAndFilterCommand.clearError();
    notifyListeners();
  }

  /// Update the displayed companies based on current search and filter
  void _updateDisplayedCompanies() {
    final allCompanies = _getCompaniesCommand.result ?? [];
    
    if (_currentSearchQuery.isEmpty && !_currentFilter.hasActiveFilters) {
      // No search or filters - show all companies
      _displayedCompanies = allCompanies;
    } else if (_currentSearchQuery.isNotEmpty && _currentFilter.hasActiveFilters) {
      // Both search and filter active - use combined command
      _searchAndFilterCommand.searchAndFilterCompanies(_currentSearchQuery, _currentFilter);
      return; // Wait for command result
    } else if (_currentSearchQuery.isNotEmpty) {
      // Only search active
      _displayedCompanies = allCompanies
          .where((company) => company.matchesSearchQuery(_currentSearchQuery))
          .toList();
    } else if (_currentFilter.hasActiveFilters) {
      // Only filter active
      _displayedCompanies = allCompanies
          .where((company) => company.matchesFilter(_currentFilter))
          .toList();
    }

    notifyListeners();
  }

  /// Listen to command state changes
  void _onCommandChanged() {
    // Update displayed companies when commands complete
    if (_searchAndFilterCommand.isCompleted) {
      _displayedCompanies = _searchAndFilterCommand.result ?? [];
    }
    
    notifyListeners();
  }

  @override
  void dispose() {
    _getCompaniesCommand.removeListener(_onCommandChanged);
    _searchCompaniesCommand.removeListener(_onCommandChanged);
    _filterCompaniesCommand.removeListener(_onCommandChanged);
    _searchAndFilterCommand.removeListener(_onCommandChanged);
    super.dispose();
  }
}