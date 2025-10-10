import 'package:flutter/material.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  List<MapBuilding> _buildings = [];
  Set<GroundOverlay> _groundOverlays = {};
  int? _selectedCompanyId;
  int _selectedFeatureModelId = 0;

  // Getters
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  List<MapLocation> get locations => _locations;
  MapLocation? get selectedLocation => _selectedLocation;
  LocationType? get filterType => _filterType;
  List<MapBuilding> get buildings => _buildings;
  Set<GroundOverlay> get groundOverlays => _groundOverlays;
  int? get selectedCompanyId => _selectedCompanyId;
  int get selectedFeatureModelId => _selectedFeatureModelId;

  /// Load all locations and buildings
  Future<bool> loadLocations() async {
    _setLoading(true);
    _clearError();

    // Load buildings
    _buildings = _mapRepository.getMapBuildings();

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

  /// Select a location
  void selectLocation(MapLocation? location) {
    _selectedLocation = location;
    notifyListeners();
  }

  /// Select a company by ID and feature model ID
  void selectCompany(int? companyId, {int featureModelId = 0}) {
    _selectedCompanyId = companyId;
    _selectedFeatureModelId = featureModelId;

    // Also update selectedLocation based on company
    if (companyId != null) {
      _selectedLocation = _locations.firstWhere(
        (loc) => loc.companyId == companyId,
        orElse: () => _locations.isNotEmpty
            ? _locations.first
            : MapLocation(
                id: FlutterNodeFloorIndex(nodeId: 0, floorIndex: 0),
                name: '',
                latitude: 0,
                longitude: 0,
                type: LocationType.booth,
                building: '',
                featureModelId: 0,
              ),
      );
    } else {
      _selectedLocation = null;
    }

    notifyListeners();
  }

  /// Clear company selection
  void clearSelection() {
    _selectedCompanyId = null;
    _selectedFeatureModelId = 0;
    _selectedLocation = null;
    notifyListeners();
  }

  /// Load ground overlays for map buildings
  Future<void> loadGroundOverlays(ImageConfiguration imageConfig) async {
    _groundOverlays = await _mapRepository.getGroundOverlays(imageConfig);
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
