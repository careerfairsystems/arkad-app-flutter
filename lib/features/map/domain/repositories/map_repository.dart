import '../../../../shared/domain/result.dart';
import '../entities/map_location.dart';

/// Repository interface for map operations
abstract class MapRepository {
  /// Get all map locations
  Future<Result<List<MapLocation>>> getLocations();

  /// Get locations by type
  Future<Result<List<MapLocation>>> getLocationsByType(LocationType type);

  List<MapBuilding> getMapBuildings();
}
