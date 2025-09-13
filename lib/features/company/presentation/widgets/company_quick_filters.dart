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
  });

  final bool hasStudentSessions;
  final Set<String> selectedPositions;
  final ValueChanged<bool> onStudentSessionsChanged;
  final ValueChanged<String> onPositionToggled;
  final VoidCallback onAdvancedFiltersPressed;
  final VoidCallback onClearAllPressed;
  final int totalActiveFilters;

  static const List<String> popularPositions = [
    'Thesis',
    'Internship', 
    'Summer Job',
  ];

  @override
  Widget build(BuildContext context) {
    final hasAnyFilters = hasStudentSessions || 
                         selectedPositions.isNotEmpty || 
                         totalActiveFilters > _getQuickFilterCount();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: ShaderMask(
              shaderCallback: (Rect bounds) {
                return LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black,
                    Colors.black,
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.03, 0.97, 1.0],
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                physics: const BouncingScrollPhysics(),
                children: [
                  const SizedBox(width: 12),
                  _buildStudentSessionsChip(context),
                  const SizedBox(width: 10),
                  ...popularPositions.map((position) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _buildPositionChip(context, position),
                  )),
                  const SizedBox(width: 4),
                  _buildMoreFiltersButton(context),
                  if (hasAnyFilters) ...[
                    const SizedBox(width: 10),
                    _buildClearAllButton(context),
                  ],
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
          
          if (hasAnyFilters) _buildActiveFiltersDisplay(context),
        ],
      ),
    );
  }

  Widget _buildStudentSessionsChip(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        elevation: hasStudentSessions ? 2 : 0,
        shadowColor: ArkadColors.arkadGreen.withValues(alpha: 0.3),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.people_rounded,
              size: 16,
              color: hasStudentSessions 
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 6),
            const Text('Student Sessions'),
          ],
        ),
        labelStyle: TextStyle(
          fontWeight: hasStudentSessions ? FontWeight.w600 : FontWeight.w500,
          color: hasStudentSessions ? Colors.white : null,
        ),
        selected: hasStudentSessions,
        onSelected: onStudentSessionsChanged,
        selectedColor: ArkadColors.arkadGreen,
        backgroundColor: hasStudentSessions 
            ? ArkadColors.arkadGreen
            : Theme.of(context).colorScheme.surface,
        checkmarkColor: Colors.white,
        side: BorderSide(
          width: hasStudentSessions ? 0 : 1.5,
          color: hasStudentSessions 
              ? Colors.transparent
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPositionChip(BuildContext context, String position) {
    final isSelected = selectedPositions.contains(position);
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: FilterChip(
        elevation: isSelected ? 2 : 0,
        shadowColor: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
        label: Text(
          position,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : null,
          ),
        ),
        selected: isSelected,
        onSelected: (_) => onPositionToggled(position),
        selectedColor: ArkadColors.arkadTurkos,
        backgroundColor: isSelected 
            ? ArkadColors.arkadTurkos
            : Theme.of(context).colorScheme.surface,
        checkmarkColor: Colors.white,
        side: BorderSide(
          width: isSelected ? 0 : 1.5,
          color: isSelected 
              ? Colors.transparent
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
        shadowColor: ArkadColors.arkadTurkos.withValues(alpha: 0.2),
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
                fontWeight: hasAdditionalFilters ? FontWeight.w600 : FontWeight.w500,
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
            : Theme.of(context).colorScheme.surface,
        side: BorderSide(
          width: hasAdditionalFilters ? 0 : 1.5,
          color: hasAdditionalFilters
              ? Colors.transparent
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildClearAllButton(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: ActionChip(
        elevation: 1,
        shadowColor: ArkadColors.lightRed.withValues(alpha: 0.2),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.clear_rounded,
              size: 16,
              color: Colors.white,
            ),
            const SizedBox(width: 6),
            Text(
              'Clear All',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        onPressed: onClearAllPressed,
        backgroundColor: ArkadColors.lightRed,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildActiveFiltersDisplay(BuildContext context) {
    final activeFilters = <String>[];
    
    if (hasStudentSessions) {
      activeFilters.add('Student Sessions');
    }
    
    activeFilters.addAll(selectedPositions);
    
    if (activeFilters.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt_rounded,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Active Filters (${activeFilters.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: activeFilters.map((filter) => Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Chip(
                label: Text(
                  filter,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                deleteIcon: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.close_rounded, 
                    size: 14,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onDeleted: () {
                  if (filter == 'Student Sessions') {
                    onStudentSessionsChanged(false);
                  } else {
                    onPositionToggled(filter);
                  }
                },
                backgroundColor: Theme.of(context).colorScheme.surface,
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                visualDensity: VisualDensity.compact,
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  int _getQuickFilterCount() {
    return (hasStudentSessions ? 1 : 0) + selectedPositions.length;
  }
}