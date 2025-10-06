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
    _degreesDebouncer.dispose();
    _industriesDebouncer.dispose();
    _competencesDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Card-like modal with rounded corners and dark surface
    final surface = Theme.of(context).colorScheme.surface;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              // Header: centered title + close button on the right
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Text(
                        'Filter Companies',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: onSurface,
                            ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded),
                        color: onSurface.withValues(alpha: 0.8),
                        onPressed: () => context.pop(),
                      ),
                    ),
                  ],
                ),
              ),
              // Segmented Tabs
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                child: Center(
                  child: TabBar(
                    controller: _tabController,
                    // larger padding for nicer pill shape
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12, // reduced from 12
                    ),
                    dividerHeight: 0,
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicator: BoxDecoration(
                      color: ArkadColors.arkadTurkos,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    indicatorPadding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    labelColor: Colors.white,
                    // dim unselected items more, like in the mock
                    unselectedLabelColor: Colors.white.withValues(alpha: 0.35),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: [
                      _buildTab(
                        title: 'Positions',
                        totalCount: FilterOptions.positions.length,
                        selectedCount: _currentFilter.positions.length,
                        icon: Icons.work_rounded,
                      ),
                      _buildTab(
                        title: 'Degrees',
                        totalCount: FilterOptions.degrees.length,
                        selectedCount: _currentFilter.degrees.length,
                        icon: Icons.school_rounded,
                      ),
                      _buildTab(
                        title: 'Industries',
                        totalCount: FilterOptions.industries.length,
                        selectedCount: _currentFilter.industries.length,
                        icon: Icons.domain_rounded,
                      ),
                      _buildTab(
                        title: 'Skills',
                        totalCount: FilterOptions.competences.length,
                        selectedCount: _currentFilter.competences.length,
                        icon: Icons.psychology_rounded,
                      ),
                    ],
                  ),
                ),
              ),
              // Replace fixed height with Expanded to avoid overflow
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
        ),
      ),
    );
  }

  // Redesigned pill tab with icon + text + count on separate rows
  Widget _buildTab({
    required String title,
    required int totalCount,
    required int selectedCount,
    required IconData icon,
  }) {
    return Tab(
      height: 55,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18), // inherits selected/unselected color
          const SizedBox(height: 6),
          Text(
            title,
            // inherits selected/unselected text style from TabBar
          ),
          const SizedBox(height: 2),
          Text(
            '$selectedCount/$totalCount',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              // keep slightly faint for readability on both states
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
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
      description: 'Select the degree levels you are pursuing',
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
      description: 'Choose industries that match your interests',
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
              color: ArkadColors.arkadTurkos.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: ArkadColors.arkadTurkos, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArkadColors.white.withValues(alpha: 0.4),
                fontWeight: FontWeight.w500,
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
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), // Added bottom padding
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ArkadColors.white.withValues(alpha: 0.5),
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.only(left: 12, right: 8),
              child: Icon(
                Icons.search_rounded,
                size: 20,
                color: ArkadColors.arkadTurkos.withValues(alpha: 0.85),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 40),
            suffixIcon: controller.text.isNotEmpty
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: ArkadColors.lightRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
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
                color: ArkadColors.lightGray.withValues(alpha: 0.18),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: ArkadColors.arkadTurkos,
                width: 2,
              ),
            ),
            filled: true,
            // Dark search field to match the modal
            fillColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.20),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }

  // Circular multi-select item list
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

    final itemBg = Theme.of(
      context,
    ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.16);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = selectedOptions.contains(option);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? ArkadColors.arkadTurkos.withValues(alpha: 0.10)
                : itemBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? ArkadColors.arkadTurkos.withValues(alpha: 0.55)
                  : ArkadColors.lightGray.withValues(alpha: 0.22),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isSelected ? 0.18 : 0.10),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
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
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    _circularIndicator(isSelected),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected
                              ? ArkadColors.arkadTurkos
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.90),
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

  Widget _circularIndicator(bool isSelected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? ArkadColors.arkadTurkos
              : ArkadColors.lightGray.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: isSelected
          ? Center(
              child: Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ArkadColors.arkadTurkos,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ArkadButton(
                      // Keep label simple like in the screenshot
                      text: 'Apply',
                      onPressed: () {
                        widget.onFiltersApplied(_currentFilter);
                        context.pop();
                      },
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
      debouncer.cancel();
      setState(() {
        onUpdate(List.from(sourceOptions));
      });
      return;
    }
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
}
