import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:get_it/get_it.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/map_location.dart';
import '../../domain/repositories/map_repository.dart';

/// Implementation of map repository (placeholder for future implementation)
class MapRepositoryImpl implements MapRepository {
  final combainSDK = GetIt.I<FlutterCombainSDK>();
  @override
  Future<Result<List<MapLocation>>> getLocations() async {
    final locations = await combainSDK
        .getRoutingProvider()
        .getAllRoutableTargetsWithPagination(
          FlutterPaginationOptions(page: 0, pageSize: 200),
        );
    // Map over locations
    final mappedLocations = locations.map((location) {
      return location.floors.keys.map((floorIndex) {
        return MapLocation(
          id: FlutterNodeFloorIndex(
            nodeId: location.nodeId,
            floorIndex: floorIndex!,
          ),
          name: location.name,
          latitude: location.latitude,
          longitude: location.longitude,
          type:
              location.metadata != null && location.metadata!['type'] == 'food'
              ? LocationType.food
              : LocationType.booth,
          imageUrl: location.imageUrl,
          companyId: location.companyId,
        );
      }).toList();
    }).toList();

    // Placeholder implementation - return empty list for now
    // In the future, this would call a remote data source
    return Result.success(<MapLocation>[]);
  }

  @override
  Future<Result<List<MapLocation>>> getLocationsByType(
    LocationType type,
  ) async {
    // Placeholder implementation
    return Result.success(<MapLocation>[]);
  }

  @override
  Future<Result<MapLocation>> getLocationById(int id) async {
    // Placeholder implementation
    return Result.failure(const UnknownError('Location not found'));
  }

  @override
  Future<Result<List<MapLocation>>> searchLocations(String query) async {
    // Placeholder implementation
    return Result.success(<MapLocation>[]);
  }

  @override
  Future<Result<void>> refreshMapData() async {
    // Placeholder implementation
    return Result.success(null);
  }
}
