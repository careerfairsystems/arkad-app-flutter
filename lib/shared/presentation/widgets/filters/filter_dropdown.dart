import 'package:flutter/material.dart';

import 'filter_dropdown_controller.dart';

/// A dropdown widget for filter options with search functionality
///
/// This widget allows selecting multiple options from a list with search capabilities.
/// It's designed to work with a FilterDropdownController to ensure only one dropdown
/// is expanded at a time.
class FilterDropdown<T> extends StatefulWidget {
  /// Unique identifier for this dropdown
  final String id;

  /// The title displayed on the dropdown header
  final String title;

  /// List of available options to select from
  final List<T> options;

  /// Currently selected values
  final Set<T> selectedValues;

  /// Callback when selection changes
  final Function(Set<T>) onSelectionChanged;

  /// Function to convert an option to a display string
  final String Function(T) displayStringForOption;

  /// Optional controller to manage dropdown expansion state
  final FilterDropdownController? controller;

  const FilterDropdown({
    super.key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    required this.displayStringForOption,
    this.controller,
    String? id,
  }) : id = id ?? title;

  @override
  State<FilterDropdown<T>> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<T> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);

    // Listen to controller changes if provided
    if (widget.controller != null) {
      widget.controller!.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (widget.controller != null) {
      widget.controller!.removeListener(_onControllerChanged);
    }
    super.dispose();
  }

  /// Handle changes from the controller
  void _onControllerChanged() {
    // If this dropdown is no longer expanded according to the controller,
    // clear the search
    if (widget.controller != null &&
        !widget.controller!.isExpanded(widget.id) &&
        _isExpanded) {
      setState(() {
        _searchController.clear();
        _searchQuery = '';
        _filteredOptions = List.from(widget.options);
      });
    }

    // Always refresh UI when controller changes
    setState(() {});
  }

  /// Whether this dropdown is currently expanded
  bool get _isExpanded {
    if (widget.controller != null) {
      return widget.controller!.isExpanded(widget.id);
    }
    return false;
  }

  /// Toggle the expanded state of this dropdown
  void _toggleDropdown() {
    if (widget.controller != null) {
      widget.controller!.setExpanded(widget.id, isExpanded: !_isExpanded);
    }
  }

  /// Update the search query and filter options
  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filterOptions();
    });
  }

  /// Filter options based on the current search query
  void _filterOptions() {
    if (_searchQuery.isEmpty) {
      _filteredOptions = List.from(widget.options);
    } else {
      _filteredOptions =
          widget.options
              .where(
                (option) => widget
                    .displayStringForOption(option)
                    .toLowerCase()
                    .contains(_searchQuery),
              )
              .toList();
    }
  }

  /// Toggle selection state of an option
  void _toggleOption(T option) {
    final newSelectedValues = Set<T>.from(widget.selectedValues);
    if (newSelectedValues.contains(option)) {
      newSelectedValues.remove(option);
    } else {
      newSelectedValues.add(option);
    }
    widget.onSelectionChanged(newSelectedValues);
  }

  /// Clear all selected options
  void _clearAll() {
    widget.onSelectionChanged({});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [_buildDropdownHeader(context), _buildExpandableContent()],
    );
  }

  /// Builds the header portion of the dropdown
  Widget _buildDropdownHeader(BuildContext context) {
    return InkWell(
      onTap: _toggleDropdown,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                _buildSelectionCounter(context),
              ],
            ),
            Icon(
              _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the selection counter badge when options are selected
  Widget _buildSelectionCounter(BuildContext context) {
    if (widget.selectedValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(left: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${widget.selectedValues.length}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Builds the expandable content section of the dropdown
  Widget _buildExpandableContent() {
    return AnimatedCrossFade(
      firstChild: _buildDropdownContent(),
      secondChild: const SizedBox.shrink(),
      crossFadeState:
          _isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
      duration: const Duration(milliseconds: 200),
      sizeCurve: Curves.easeInOut,
    );
  }

  /// Builds the content shown when the dropdown is expanded
  Widget _buildDropdownContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSearchField(),
        _buildOptionsContainer(),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Builds the search field for filtering options
  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search ${widget.title.toLowerCase()}...',
          prefixIcon: const Icon(Icons.search, size: 20),
          contentPadding: const EdgeInsets.symmetric(),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      _updateSearch('');
                    },
                  )
                  : null,
        ),
        onChanged: _updateSearch,
      ),
    );
  }

  /// Builds the container for the options list with scroll constraints
  Widget _buildOptionsContainer() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.options.length > 10 ? 200 : 150,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [_buildClearAllButton(), _buildOptionsList()],
        ),
      ),
    );
  }

  /// Builds the clear all button when selections exist
  Widget _buildClearAllButton() {
    if (widget.selectedValues.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.clear_all, size: 16),
            label: const Text('Clear all'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _clearAll,
          ),
        ],
      ),
    );
  }

  /// Builds the list of options or an empty state
  Widget _buildOptionsList() {
    if (_filteredOptions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text(
          'No options match search',
          textAlign: TextAlign.center,
          style: TextStyle(fontStyle: FontStyle.italic),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _filteredOptions.length,
      itemBuilder: (context, index) {
        final option = _filteredOptions[index];
        final isSelected = widget.selectedValues.contains(option);

        return CheckboxListTile(
          title: Text(
            widget.displayStringForOption(option),
            style: const TextStyle(fontSize: 14),
          ),
          value: isSelected,
          onChanged: (_) => _toggleOption(option),
          dense: true,
          contentPadding: const EdgeInsets.symmetric(),
          controlAffinity: ListTileControlAffinity.leading,
          activeColor: Theme.of(context).colorScheme.primary,
          tileColor:
              isSelected
                  ? Theme.of(
                    context,
                  ).colorScheme.primaryContainer.withValues(alpha: .2)
                  : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          visualDensity: VisualDensity.compact,
        );
      },
    );
  }
}
