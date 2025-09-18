import 'package:flutter/material.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/map_location.dart';
import '../../domain/repositories/map_repository.dart';

/// ViewModel for managing map state and operations
class MapViewModel extends ChangeNotifier {
  final MapRepository _mapRepository;

  MapViewModel({required MapRepository mapRepository})
    : _mapRepository = mapRepository;

  // State
  bool _isLoading = false;
  AppError? _error;
  List<MapLocation> _locations = [];
  MapLocation? _selectedLocation;
  LocationType? _filterType;

  // Getters
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  List<MapLocation> get locations => _locations;
  MapLocation? get selectedLocation => _selectedLocation;
  LocationType? get filterType => _filterType;

  /// Load all locations
  Future<bool> loadLocations() async {
    _setLoading(true);
    _clearError();

    final result = await _mapRepository.getLocations();

    result.when(
      success: (locations) {
        _locations = locations;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Filter locations by type
  Future<void> filterByType(LocationType? type) async {
    _filterType = type;

    if (type == null) {
      await loadLocations();
      return;
    }

    _setLoading(true);
    _clearError();

    final result = await _mapRepository.getLocationsByType(type);

    result.when(
      success: (locations) {
        _locations = locations;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );
  }

  /// Search locations
  Future<void> searchLocations(String query) async {
    if (query.isEmpty) {
      await loadLocations();
      return;
    }

    _setLoading(true);
    _clearError();

    final result = await _mapRepository.searchLocations(query);

    result.when(
      success: (locations) {
        _locations = locations;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );
  }

  /// Select a location
  void selectLocation(MapLocation? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  /// Refresh map data
  Future<void> refreshMapData() async {
    await loadLocations();
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(AppError? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
