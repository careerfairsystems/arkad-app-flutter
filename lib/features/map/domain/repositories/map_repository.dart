import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../entities/map_location.dart';

/// Repository interface for map operations
abstract class MapRepository {
  /// Get all map locations
  Future<Result<List<MapLocation>>> getLocations();

  /// Get locations by type
  Future<Result<List<MapLocation>>> getLocationsByType(LocationType type);

  List<MapBuilding> getMapBuildings();

  /// Get ground overlays for map buildings
  Future<Set<GroundOverlay>> getGroundOverlays(ImageConfiguration imageConfig);

  ///   Gets the most likely building for a given area
  /// If position is no building inside, returns null
  /// Otherwise return the building that has the largest area inside the given position
  MapBuilding? mostLikelyBuilding(LatLngBounds position);
}
