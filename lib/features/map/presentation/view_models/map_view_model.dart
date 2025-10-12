import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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
  Map<int, int> buildingIdToFloorIndex = {};
  int? get selectedCompanyId => _selectedCompanyId;
  int get selectedFeatureModelId => _selectedFeatureModelId;
  late ImageConfiguration _imageConfig;

  /// Load all locations and buildings
  Future<bool> loadLocations() async {
    _setLoading(true);
    _clearError();

    // Load buildings
    _buildings = _mapRepository.getMapBuildings();
    if (buildingIdToFloorIndex.isEmpty) {
      for (var building in _buildings) {
        buildingIdToFloorIndex[building.id] = building.defaultFloorIndex;
      }
    }

    final result = await _mapRepository.getLocations(buildingIdToFloorIndex);

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
      // Check if locations are loaded
      if (_locations.isEmpty && !_isLoading) {
        debugPrint(
          'Locations not loaded yet for company selection: $companyId',
        );
        _selectedLocation = null;

        Sentry.logger.error(
          'Attempted to select company before locations loaded',
          attributes: {
            'company_id': SentryLogAttribute.string(companyId.toString()),
            'locations_count': SentryLogAttribute.string('0'),
            'is_loading': SentryLogAttribute.string('false'),
          },
        );
      } else {
        try {
          _selectedLocation = _locations.firstWhere(
            (loc) => loc.companyId == companyId,
          );

          Sentry.logger.info(
            'Company selected with valid location',
            attributes: {
              'company_id': SentryLogAttribute.string(companyId.toString()),
              'feature_model_id': SentryLogAttribute.string(
                featureModelId.toString(),
              ),
              'locations_count': SentryLogAttribute.string(
                _locations.length.toString(),
              ),
            },
          );
        } catch (e) {
          // No location found for this company - don't set a fallback
          // This prevents zooming to wrong locations
          _selectedLocation = null;
          debugPrint('No map location found for company ID: $companyId');

          Sentry.logger.error(
            'No map location found for company',
            attributes: {
              'company_id': SentryLogAttribute.string(companyId.toString()),
              'locations_count': SentryLogAttribute.string(
                _locations.length.toString(),
              ),
            },
          );
        }
      }
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
    _imageConfig = imageConfig;
    _groundOverlays = await _mapRepository.getGroundOverlays(
      imageConfig,
      buildingIdToFloorIndex,
    );
  }

  void updateBuildingFloor(int buildingId, int floorIndex) async {
    buildingIdToFloorIndex[buildingId] = floorIndex;
    await loadLocations();
    await loadGroundOverlays(_imageConfig);
    notifyListeners();
  }

  int? getBuildingFloor(int buildingId) {
    return buildingIdToFloorIndex[buildingId];
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
