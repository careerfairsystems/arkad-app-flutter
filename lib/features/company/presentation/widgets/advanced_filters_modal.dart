import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/infrastructure/debouncer.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/company.dart';
import 'filter_options.dart';

class AdvancedFiltersModal extends StatefulWidget {
  const AdvancedFiltersModal({
    super.key,
    required this.initialFilter,
    required this.onFiltersApplied,
  });

  final CompanyFilter initialFilter;
  final ValueChanged<CompanyFilter> onFiltersApplied;

  @override
  State<AdvancedFiltersModal> createState() => _AdvancedFiltersModalState();
}

class _AdvancedFiltersModalState extends State<AdvancedFiltersModal>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CompanyFilter _currentFilter;

  final TextEditingController _degreesSearchController =
      TextEditingController();
  final TextEditingController _industriesSearchController =
      TextEditingController();
  final TextEditingController _competencesSearchController =
      TextEditingController();

  List<String> _filteredDegrees = [];
  List<String> _filteredIndustries = [];
  List<String> _filteredCompetences = [];

  // Search debouncing
  final FilterDebouncer _degreesDebouncer = FilterDebouncer();
  final FilterDebouncer _industriesDebouncer = FilterDebouncer();
  final FilterDebouncer _competencesDebouncer = FilterDebouncer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentFilter = widget.initialFilter.copyWith();

    _filteredDegrees = List.from(FilterOptions.degrees);
    _filteredIndustries = List.from(FilterOptions.industries);
    _filteredCompetences = List.from(FilterOptions.competences);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _degreesSearchController.dispose();
    _industriesSearchController.dispose();
    _competencesSearchController.dispose();

    // Dispose search debouncers
    _degreesDebouncer.dispose();
    _industriesDebouncer.dispose();
    _competencesDebouncer.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArkadColors.white,
      appBar: AppBar(
        title: const Text('Filter Companies'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        backgroundColor: ArkadColors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: ArkadColors.lightGray.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              tabs: [
                _buildTab(
                  'Positions',
                  FilterOptions.positions.length,
                  _currentFilter.positions.length,
                ),
                _buildTab(
                  'Degrees',
                  FilterOptions.degrees.length,
                  _currentFilter.degrees.length,
                ),
                _buildTab(
                  'Industries',
                  FilterOptions.industries.length,
                  _currentFilter.industries.length,
                ),
                _buildTab(
                  'Skills',
                  FilterOptions.competences.length,
                  _currentFilter.competences.length,
                ),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: ArkadColors.gray.withValues(alpha: 0.7),
              indicator: BoxDecoration(
                color: ArkadColors.arkadTurkos,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              dividerHeight: 0,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 2,
                vertical: 2,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPositionsTab(),
                _buildDegreesTab(),
                _buildIndustriesTab(),
                _buildCompetencesTab(),
              ],
            ),
          ),
          _buildBottomActions(),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int totalCount, int selectedCount) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$selectedCount'),
                Text(
                  '/$totalCount',
                  style: TextStyle(
                    fontSize: 10,
                    color: ArkadColors.gray.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionsTab() {
    return _buildFilterSection(
      options: FilterOptions.positions,
      selectedOptions: _currentFilter.positions.toSet(),
      onSelectionChanged: (selected) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(
            positions: selected.toList(),
          );
        });
      },
      icon: Icons.work_rounded,
      description: 'Select the types of positions you\'re interested in',
    );
  }

  Widget _buildDegreesTab() {
    return _buildSearchableFilterSection(
      options: _filteredDegrees,
      selectedOptions: _currentFilter.degrees.toSet(),
      searchController: _degreesSearchController,
      onSelectionChanged: (selected) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(degrees: selected.toList());
        });
      },
      onSearchChanged: (query) => _filterDegrees(query),
      icon: Icons.school_rounded,
      description: 'Filter companies by required academic degrees',
      searchHint: 'Search degrees...',
    );
  }

  Widget _buildIndustriesTab() {
    return _buildSearchableFilterSection(
      options: _filteredIndustries,
      selectedOptions: _currentFilter.industries.toSet(),
      searchController: _industriesSearchController,
      onSelectionChanged: (selected) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(
            industries: selected.toList(),
          );
        });
      },
      onSearchChanged: (query) => _filterIndustries(query),
      icon: Icons.domain_rounded,
      description: 'Find companies in specific industry sectors',
      searchHint: 'Search industries...',
    );
  }

  Widget _buildCompetencesTab() {
    return _buildSearchableFilterSection(
      options: _filteredCompetences,
      selectedOptions: _currentFilter.competences.toSet(),
      searchController: _competencesSearchController,
      onSelectionChanged: (selected) {
        setState(() {
          _currentFilter = _currentFilter.copyWith(
            competences: selected.toList(),
          );
        });
      },
      onSearchChanged: (query) => _filterCompetences(query),
      icon: Icons.psychology_rounded,
      description:
          'Match companies seeking your specific skills and competences',
      searchHint: 'Search competences...',
    );
  }

  Widget _buildFilterSection({
    required List<String> options,
    required Set<String> selectedOptions,
    required ValueChanged<Set<String>> onSelectionChanged,
    required IconData icon,
    required String description,
  }) {
    return Column(
      children: [
        _buildSectionHeader(icon, description),
        Expanded(
          child: _buildOptionsList(
            options,
            selectedOptions,
            onSelectionChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableFilterSection({
    required List<String> options,
    required Set<String> selectedOptions,
    required TextEditingController searchController,
    required ValueChanged<Set<String>> onSelectionChanged,
    required ValueChanged<String> onSearchChanged,
    required IconData icon,
    required String description,
    required String searchHint,
  }) {
    return Column(
      children: [
        _buildSectionHeader(icon, description),
        _buildSearchField(searchController, searchHint, onSearchChanged),
        Expanded(
          child: _buildOptionsList(
            options,
            selectedOptions,
            onSelectionChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String description) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: ArkadColors.arkadTurkos, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArkadColors.gray.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(
    TextEditingController controller,
    String hint,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: ArkadColors.gray.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ArkadColors.gray.withValues(alpha: 0.5),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: ArkadColors.arkadTurkos.withValues(alpha: 0.7),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon:
                controller.text.isNotEmpty
                    ? Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: ArkadColors.lightRed.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.clear_rounded,
                            size: 16,
                            color: ArkadColors.lightRed,
                          ),
                        ),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      ),
                    )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: ArkadColors.lightGray.withValues(alpha: 0.2),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: ArkadColors.arkadTurkos, width: 2),
            ),
            filled: true,
            fillColor: ArkadColors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildOptionsList(
    List<String> options,
    Set<String> selectedOptions,
    ValueChanged<Set<String>> onSelectionChanged,
  ) {
    if (options.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: ArkadColors.gray.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 16),
              Text(
                'No options match your search',
                style: TextStyle(
                  color: ArkadColors.gray.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOptions.contains(option);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? ArkadColors.arkadTurkos.withValues(alpha: 0.12)
                    : ArkadColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  isSelected
                      ? ArkadColors.arkadTurkos.withValues(alpha: 0.4)
                      : ArkadColors.lightGray.withValues(alpha: 0.2),
              width: isSelected ? 2 : 1,
            ),
            boxShadow:
                isSelected
                    ? [
                      BoxShadow(
                        color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                    : null,
          ),
          child: Material(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                final newSelection = Set<String>.from(selectedOptions);
                if (isSelected) {
                  newSelection.remove(option);
                } else {
                  newSelection.add(option);
                }
                onSelectionChanged(newSelection);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? ArkadColors.arkadTurkos
                                : Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.0),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color:
                              isSelected
                                  ? ArkadColors.arkadTurkos
                                  : ArkadColors.lightGray.withValues(
                                    alpha: 0.5,
                                  ),
                          width: 2,
                        ),
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                              : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                          color:
                              isSelected
                                  ? ArkadColors.arkadTurkos
                                  : ArkadColors.gray,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomActions() {
    final totalSelected =
        _currentFilter.degrees.length +
        _currentFilter.positions.length +
        _currentFilter.industries.length +
        _currentFilter.competences.length +
        (_currentFilter.hasStudentSessions ? 1 : 0);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: ArkadColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: ArkadColors.gray.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (totalSelected > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  '$totalSelected filter${totalSelected == 1 ? '' : 's'} will be applied',
                  style: TextStyle(
                    color: ArkadColors.arkadTurkos,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            if (totalSelected > 0) const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ArkadButton(
                    text: 'Clear All',
                    onPressed: totalSelected > 0 ? _clearAllFilters : null,
                    variant: ArkadButtonVariant.secondary,
                    icon: Icons.clear_all_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ArkadButton(
                      text:
                          totalSelected > 0
                              ? 'Apply ($totalSelected)'
                              : 'Apply Filters',
                      onPressed: () {
                        widget.onFiltersApplied(_currentFilter);
                        context.pop();
                      },
                      icon: Icons.check_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _filterItems({
    required String query,
    required FilterDebouncer debouncer,
    required List<String> sourceOptions,
    required void Function(List<String>) onUpdate,
  }) {
    if (query.isEmpty) {
      // Update immediately for empty queries
      debouncer.cancel();
      setState(() {
        onUpdate(List.from(sourceOptions));
      });
      return;
    }

    // Debounce non-empty queries
    debouncer.call(() {
      if (mounted) {
        setState(() {
          onUpdate(
            sourceOptions
                .where(
                  (item) => item.toLowerCase().contains(query.toLowerCase()),
                )
                .toList(),
          );
        });
      }
    });
  }

  void _filterDegrees(String query) {
    _filterItems(
      query: query,
      debouncer: _degreesDebouncer,
      sourceOptions: FilterOptions.degrees,
      onUpdate: (filtered) => _filteredDegrees = filtered,
    );
  }

  void _filterIndustries(String query) {
    _filterItems(
      query: query,
      debouncer: _industriesDebouncer,
      sourceOptions: FilterOptions.industries,
      onUpdate: (filtered) => _filteredIndustries = filtered,
    );
  }

  void _filterCompetences(String query) {
    _filterItems(
      query: query,
      debouncer: _competencesDebouncer,
      sourceOptions: FilterOptions.competences,
      onUpdate: (filtered) => _filteredCompetences = filtered,
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
  }
}
