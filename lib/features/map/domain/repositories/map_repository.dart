import '../../../../shared/domain/result.dart';
import '../entities/map_location.dart';

/// Repository interface for map operations
abstract class MapRepository {
  /// Get all map locations
  Future<Result<List<MapLocation>>> getLocations();

  /// Get locations by type
  Future<Result<List<MapLocation>>> getLocationsByType(LocationType type);

  /// Get location by ID
  Future<Result<MapLocation>> getLocationById(int id);

  /// Search locations by name or description
  Future<Result<List<MapLocation>>> searchLocations(String query);

  /// Refresh cached map data
  Future<Result<void>> refreshMapData();
}