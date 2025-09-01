import 'package:flutter/material.dart';

/// Controller that ensures only one FilterDropdown is expanded at a time
class FilterDropdownController extends ChangeNotifier {
  String? _expandedDropdownId;

  /// Get the currently expanded dropdown ID
  String? get expandedDropdownId => _expandedDropdownId;

  /// Set a dropdown as expanded and collapse any other expanded dropdown
  void setExpanded(String dropdownId, {bool isExpanded = true}) {
    if (isExpanded) {
      if (_expandedDropdownId != dropdownId) {
        _expandedDropdownId = dropdownId;
        notifyListeners();
      }
    } else if (_expandedDropdownId == dropdownId) {
      _expandedDropdownId = null;
      notifyListeners();
    }
  }

  /// Check if a specific dropdown is expanded
  bool isExpanded(String dropdownId) {
    return _expandedDropdownId == dropdownId;
  }

  /// Collapse all dropdowns
  void collapseAll() {
    if (_expandedDropdownId != null) {
      _expandedDropdownId = null;
      notifyListeners();
    }
  }
}
