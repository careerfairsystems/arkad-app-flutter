import 'package:flutter/material.dart';

class FilterDropdown<T> extends StatefulWidget {
  final String title;
  final List<T> options;
  final Set<T> selectedValues;
  final Function(Set<T>) onSelectionChanged;
  final String Function(T) displayStringForOption;

  const FilterDropdown({
    Key? key,
    required this.title,
    required this.options,
    required this.selectedValues,
    required this.onSelectionChanged,
    required this.displayStringForOption,
  }) : super(key: key);

  @override
  _FilterDropdownState<T> createState() => _FilterDropdownState<T>();
}

class _FilterDropdownState<T> extends State<FilterDropdown<T>> {
  bool _isExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<T> _filteredOptions;

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
  }

  void _toggleDropdown() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        // Clear search when closing dropdown
        _searchController.clear();
        _searchQuery = '';
        _filteredOptions = List.from(widget.options);
      }
    });
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
      _filterOptions();
    });
  }

  void _filterOptions() {
    if (_searchQuery.isEmpty) {
      _filteredOptions = List.from(widget.options);
    } else {
      _filteredOptions = widget.options
          .where((option) => widget
              .displayStringForOption(option)
              .toLowerCase()
              .contains(_searchQuery))
          .toList();
    }
  }

  void _toggleOption(T option) {
    final newSelectedValues = Set<T>.from(widget.selectedValues);
    if (newSelectedValues.contains(option)) {
      newSelectedValues.remove(option);
    } else {
      newSelectedValues.add(option);
    }
    widget.onSelectionChanged(newSelectedValues);
  }

  void _clearAll() {
    widget.onSelectionChanged({});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dropdown header
        InkWell(
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
                    if (widget.selectedValues.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
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
                      ),
                  ],
                ),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                ),
              ],
            ),
          ),
        ),

        // Dropdown content (expandable)
        AnimatedCrossFade(
          firstChild: _buildDropdownContent(context),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _isExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildDropdownContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search ${widget.title.toLowerCase()}...',
              prefixIcon: const Icon(Icons.search, size: 20),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              suffixIcon: _searchQuery.isNotEmpty
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
        ),

        // Options list
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Clear all row at top
                if (widget.selectedValues.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.clear_all, size: 16),
                          label: const Text('Clear all'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _clearAll,
                        ),
                      ],
                    ),
                  ),

                // Option checkboxes
                if (_filteredOptions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'No options match search',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredOptions.length,
                    itemBuilder: (context, index) {
                      final option = _filteredOptions[index];
                      final isSelected = widget.selectedValues.contains(option);
                      return CheckboxListTile(
                        title: Text(widget.displayStringForOption(option)),
                        value: isSelected,
                        onChanged: (_) => _toggleOption(option),
                        dense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 0),
                        controlAffinity: ListTileControlAffinity.leading,
                        activeColor: Theme.of(context).colorScheme.primary,
                        tileColor: isSelected
                            ? Theme.of(context)
                                .colorScheme
                                .primaryContainer
                                .withOpacity(0.2)
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
