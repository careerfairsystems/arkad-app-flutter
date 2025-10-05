import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';

class CompanyQuickFilters extends StatelessWidget {
  const CompanyQuickFilters({
    super.key,
    required this.hasStudentSessions,
    required this.selectedPositions,
    required this.onStudentSessionsChanged,
    required this.onPositionToggled,
    required this.onAdvancedFiltersPressed,
    required this.onClearAllPressed,
    this.totalActiveFilters = 0,
    required this.resultsCount,
    required this.totalCompanies,
    this.hasSearchQuery = false,
  });

  final bool hasStudentSessions;
  final Set<String> selectedPositions;
  final ValueChanged<bool> onStudentSessionsChanged;
  final ValueChanged<String> onPositionToggled;
  final VoidCallback onAdvancedFiltersPressed;
  final VoidCallback onClearAllPressed;
  final int totalActiveFilters;

  final int resultsCount;
  final int totalCompanies;
  final bool hasSearchQuery;

  static const List<String> popularPositions = [
    'Student Sessions',
    'Thesis',
    'Internship',
    'Summer Job',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: [0.0, 0.03, 0.97, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(width: 10),
                  ...popularPositions.map(
                    (position) => Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: _buildPositionChip(context, position),
                    ),
                  ),
                  const SizedBox(width: 2),
                  _buildMoreFiltersButton(context),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),

          _buildActiveInfoRow(context),
        ],
      ),
    );
  }

  Widget _buildPositionChip(BuildContext context, String position) {
    final isSelected = selectedPositions.contains(position);

    return AnimatedContainer(
      duration: const Duration(),
      curve: Curves.easeInOut,
      child: FilterChip(
        elevation: isSelected ? 2 : 0,
        label: Text(
          position,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : null,
          ),
        ),
        selected: isSelected,
        showCheckmark: false,
        onSelected: (_) => onPositionToggled(position),
        selectedColor: ArkadColors.arkadTurkos,
        backgroundColor: isSelected
            ? ArkadColors.arkadTurkos
            : ArkadColors.arkadLightNavy,
        side: BorderSide(
          color: isSelected
              ? Colors.transparent
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  Widget _buildMoreFiltersButton(BuildContext context) {
    final additionalFilters = totalActiveFilters - _getQuickFilterCount();
    final hasAdditionalFilters = additionalFilters > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ActionChip(
        elevation: hasAdditionalFilters ? 1 : 0,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 16,
              color: hasAdditionalFilters ? Colors.white : null,
            ),
            const SizedBox(width: 6),
            Text(
              'More Filters',
              style: TextStyle(
                fontWeight: hasAdditionalFilters
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: hasAdditionalFilters ? Colors.white : null,
              ),
            ),
            if (hasAdditionalFilters) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Text(
                  '$additionalFilters',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        onPressed: onAdvancedFiltersPressed,
        backgroundColor: hasAdditionalFilters
            ? ArkadColors.arkadTurkos
            : ArkadColors.arkadLightNavy,
        side: BorderSide(
          width: hasAdditionalFilters ? 0 : 0.5,
          color: hasAdditionalFilters
              ? Colors.transparent
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
      ),
    );
  }

  Widget _buildActiveInfoRow(BuildContext context) {
    final int activeCount =
        (hasStudentSessions ? 1 : 0) + selectedPositions.length;

    final bool showResults = hasSearchQuery || activeCount > 0;
    final bool showClear = activeCount > 0;

    if (!showResults && !showClear) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
      child: Row(
        children: [
          if (showResults)
            Container(
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
                  const Icon(
                    Icons.filter_list_rounded,
                    size: 16,
                    color: ArkadColors.arkadTurkos,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Showing $resultsCount of $totalCompanies companies',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
          if (showClear)
            InkWell(
              onTap: onClearAllPressed,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: ArkadColors.lightRed,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Clear all filters ($activeCount)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: ArkadColors.lightRed,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  int _getQuickFilterCount() {
    return (hasStudentSessions ? 1 : 0) + selectedPositions.length;
  }
}
