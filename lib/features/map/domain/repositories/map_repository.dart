import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../entities/map_location.dart';

/// Repository interface for map operations
abstract class MapRepository {
  /// Get all map locations
  /// Only for the specified floor in each building
  Future<Result<List<MapLocation>>> getLocationsForFloor(
    Map<int, int> buildingIdToFloorIndex,
  );

  /// Get all map locations for all buildings and floors
  /// Grouped by building ID
  Future<Result<Map<int, List<MapLocation>>>> getLocationsForBuilding();

  List<MapBuilding> getMapBuildings();

  /// Get building name by building ID
  /// Returns null if building is not found
  String? getBuildingName(int buildingId);

  /// Get available floors for a building by building ID
  /// Returns empty list if building is not found
  List<(int floorIndex, String floorLabel)> getAvailableFloors(int buildingId);

  /// Get floor label for a specific building and floor index
  /// Returns null if building or floor is not found
  String? getFloorLabel(int buildingId, int floorIndex);

  /// Get ground overlays for map buildings
  Future<Set<GroundOverlay>> getGroundOverlays(
    ImageConfiguration imageConfig,
    Map<int, int> buildingIdToFloorIndex,
  );

  ///   Gets the most likely building for a given area
  /// If position is no building inside, returns null
  /// Otherwise return the building that has the largest area inside the given position
  MapBuilding? mostLikelyBuilding(LatLngBounds position);
}
