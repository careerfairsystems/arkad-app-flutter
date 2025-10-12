import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/infrastructure/debouncer.dart';
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

    // Subscribe to logout events for cleanup
    _subscribeToLogoutEvents();
  }

  final GetCompaniesCommand _getCompaniesCommand;
  final SearchCompaniesCommand _searchCompaniesCommand;
  final FilterCompaniesCommand _filterCompaniesCommand;
  final SearchAndFilterCompaniesCommand _searchAndFilterCommand;

  // Search debouncing
  final SearchDebouncer _searchDebouncer = SearchDebouncer();
  bool _isSearching = false;

  // Current state
  String _currentSearchQuery = '';
  CompanyFilter _currentFilter = const CompanyFilter();
  List<Company> _displayedCompanies = [];

  // Epoch guard to prevent race conditions from stale command completions
  int _commandsEpoch = 0;

  // Track which epoch each command was started in
  int _searchAndFilterCommandEpoch = 0;
  int _searchCompaniesCommandEpoch = 0;
  int _filterCompaniesCommandEpoch = 0;

  // Stream subscription for logout events
  StreamSubscription? _logoutSubscription;

  // Command getters (for direct access if needed)
  GetCompaniesCommand get getCompaniesCommand => _getCompaniesCommand;
  SearchCompaniesCommand get searchCompaniesCommand => _searchCompaniesCommand;
  FilterCompaniesCommand get filterCompaniesCommand => _filterCompaniesCommand;
  SearchAndFilterCompaniesCommand get searchAndFilterCommand =>
      _searchAndFilterCommand;

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

  bool get isSearching => _isSearching;

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

  /// Search companies by query with debouncing
  Future<void> searchCompanies(String query) async {
    _currentSearchQuery = query;

    // For empty queries, update immediately for better UX
    if (query.isEmpty) {
      _searchDebouncer.cancel();
      _isSearching = false;
      _updateDisplayedCompanies();
      return;
    }

    // Show searching state immediately
    if (!_isSearching) {
      _isSearching = true;
      notifyListeners();
    }

    // Debounce the actual search operation
    _searchDebouncer.call(() => _performDebouncedSearch(query));
  }

  /// Search companies immediately without debouncing (for filter applications)
  Future<void> searchCompaniesImmediately(String query) async {
    _searchDebouncer.cancel();
    _currentSearchQuery = query;
    _updateDisplayedCompanies();
  }

  /// Performs the actual search operation after debouncing
  Future<void> _performDebouncedSearch(String query) async {
    // Only proceed if the query hasn't changed during debouncing
    if (_currentSearchQuery == query) {
      _updateDisplayedCompanies();
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Filter companies by criteria
  Future<void> filterCompanies(CompanyFilter filter) async {
    _currentFilter = filter;
    _updateDisplayedCompanies();
  }

  /// Update search query and filter simultaneously
  Future<void> searchAndFilterCompanies(
    String query,
    CompanyFilter filter,
  ) async {
    _searchDebouncer.cancel();
    _currentSearchQuery = query;
    _currentFilter = filter;
    _isSearching = false;
    _updateDisplayedCompanies();
  }

  /// Clear search query
  void clearSearch() {
    _searchDebouncer.cancel();
    _currentSearchQuery = '';
    _isSearching = false;
    _updateDisplayedCompanies();
  }

  /// Clear all filters
  void clearFilters() {
    _currentFilter = const CompanyFilter();
    _updateDisplayedCompanies();
  }

  /// Clear both search and filters
  void clearAll() {
    _searchDebouncer.cancel();
    _currentSearchQuery = '';
    _currentFilter = const CompanyFilter();
    _isSearching = false;
    _updateDisplayedCompanies();
  }

  /// Get a specific company by ID
  Company? getCompanyById(int id) {
    try {
      return allCompanies.firstWhere((company) => company.id == id);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
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

  /// Filter companies by visibility in company list
  /// This ensures hidden companies are excluded from main display
  /// but still available via getCompanyById (for student sessions)
  List<Company> _filterByVisibility(List<Company> companies) {
    return companies.where((company) => company.visibleInCompanyList).toList();
  }

  /// Clear any errors
  void clearError() {
    _getCompaniesCommand.clearError();
    _searchCompaniesCommand.clearError();
    _filterCompaniesCommand.clearError();
    _searchAndFilterCommand.clearError();
    notifyListeners();
  }

  /// Subscribe to logout events for cleanup
  void _subscribeToLogoutEvents() {
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _handleUserLogout();
    });
  }

  /// Handle user logout by clearing user-specific state but preserving public company data
  void _handleUserLogout() {
    // Clear user interaction state (search and filters)
    _currentSearchQuery = '';
    _currentFilter = const CompanyFilter();

    // Reset search and filter commands (user-specific operations)
    _searchCompaniesCommand.reset();
    _filterCompaniesCommand.reset();
    _searchAndFilterCommand.reset();

    _updateDisplayedCompanies();

    notifyListeners();
  }

  void _updateDisplayedCompanies() {
    // Increment epoch to invalidate any in-flight command results
    // This prevents stale completions from overwriting newer results
    _commandsEpoch++;

    if (_currentSearchQuery.isEmpty && !_currentFilter.hasActiveFilters) {
      // Reset all filter/search commands when showing all companies
      _searchAndFilterCommand.reset(notify: false);
      _searchCompaniesCommand.reset(notify: false);
      _filterCompaniesCommand.reset(notify: false);
      _displayedCompanies = _filterByVisibility(
        _getCompaniesCommand.result ?? [],
      );
    } else if (_currentSearchQuery.isNotEmpty &&
        _currentFilter.hasActiveFilters) {
      // Reset other commands when using search + filter
      _searchCompaniesCommand.reset(notify: false);
      _filterCompaniesCommand.reset(notify: false);
      _searchAndFilterCommandEpoch = _commandsEpoch; // Record epoch
      _searchAndFilterCommand.searchAndFilterCompanies(
        _currentSearchQuery,
        _currentFilter,
      );
      return;
    } else if (_currentSearchQuery.isNotEmpty) {
      // Reset other commands when using search only
      _searchAndFilterCommand.reset(notify: false);
      _filterCompaniesCommand.reset(notify: false);
      _searchCompaniesCommandEpoch = _commandsEpoch; // Record epoch
      _searchCompaniesCommand.searchCompanies(_currentSearchQuery);
      return;
    } else if (_currentFilter.hasActiveFilters) {
      // Reset other commands when using filter only
      _searchAndFilterCommand.reset(notify: false);
      _searchCompaniesCommand.reset(notify: false);
      _filterCompaniesCommandEpoch = _commandsEpoch; // Record epoch
      _filterCompaniesCommand.filterCompanies(_currentFilter);
      return;
    }

    notifyListeners();
  }

  void _onCommandChanged() {
    final totalCompanies = allCompanies.length;

    // Check each command and only update if it's from the current epoch
    // This prevents stale command completions from overwriting newer results
    if (_searchAndFilterCommand.isCompleted &&
        _searchAndFilterCommandEpoch == _commandsEpoch) {
      _displayedCompanies = _filterByVisibility(
        _searchAndFilterCommand.result ?? [],
      );

      // Log intersection of search AND filter
      if (kDebugMode) {
        print(
          '[CompanyViewModel] Search + Filter INTERSECTION: '
          'total=$totalCompanies → result=${_displayedCompanies.length} | '
          'query="$_currentSearchQuery", '
          'filters: ${_currentFilter.positions.length} positions, '
          '${_currentFilter.degrees.length} degrees, '
          '${_currentFilter.industries.length} industries',
        );
      }
    } else if (_searchCompaniesCommand.isCompleted &&
        _searchCompaniesCommandEpoch == _commandsEpoch) {
      _displayedCompanies = _filterByVisibility(
        _searchCompaniesCommand.result ?? [],
      );

      // Log search-only results
      if (kDebugMode) {
        print(
          '[CompanyViewModel] Search ONLY: '
          'total=$totalCompanies → result=${_displayedCompanies.length} | '
          'query="$_currentSearchQuery"',
        );
      }
    } else if (_filterCompaniesCommand.isCompleted &&
        _filterCompaniesCommandEpoch == _commandsEpoch) {
      _displayedCompanies = _filterByVisibility(
        _filterCompaniesCommand.result ?? [],
      );

      // Log filter-only results
      if (kDebugMode) {
        print(
          '[CompanyViewModel] Filter ONLY: '
          'total=$totalCompanies → result=${_displayedCompanies.length} | '
          'filters: ${_currentFilter.positions.length} positions, '
          '${_currentFilter.degrees.length} degrees, '
          '${_currentFilter.industries.length} industries',
        );
      }
    } else if (_getCompaniesCommand.isCompleted &&
        _currentSearchQuery.isEmpty &&
        !_currentFilter.hasActiveFilters) {
      _displayedCompanies = _filterByVisibility(
        _getCompaniesCommand.result ?? [],
      );

      // Log showing all companies (no filters)
      if (kDebugMode) {
        print(
          '[CompanyViewModel] Showing ALL companies (no filters): total=$totalCompanies',
        );
      }
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _getCompaniesCommand.removeListener(_onCommandChanged);
    _searchCompaniesCommand.removeListener(_onCommandChanged);
    _filterCompaniesCommand.removeListener(_onCommandChanged);
    _searchAndFilterCommand.removeListener(_onCommandChanged);

    // Cancel logout event subscription
    _logoutSubscription?.cancel();

    // Dispose search debouncer
    _searchDebouncer.dispose();

    super.dispose();
  }
}
