import 'package:arkad/features/company/domain/entities/company.dart';
import 'package:arkad/features/company/domain/repositories/company_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/map_location.dart';
import '../../domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  // Building ID constants
  static const int studyCBuildingId = 261376248;
  static const int guildHouseBuildingId = 1834;
  static const int eHouseBuildingId = 261376246;

  final combainSDK = GetIt.I<FlutterCombainSDK>();
  final CompanyRepository companyRepository = GetIt.I<CompanyRepository>();

  Future<Company?> _companyFromRoutableTarget(
    FlutterRoutableTarget target,
  ) async {
    final companies = await companyRepository.getCompanies();
    if (companies.isFailure) return null;

    final companyList = companies.valueOrNull;
    if (companyList == null) return null;

    try {
      return companyList.firstWhere((company) => company.name == target.name);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Result<List<MapLocation>>> getLocations() async {
    try {
      final locations = await combainSDK
          .getRoutingProvider()
          .getAllRoutableTargetsWithPagination(
            FlutterPaginationOptions(page: 0, pageSize: 1000),
          );
      // Map over locations and await all futures
      final mappedLocationsFutures = locations.map((location) async {
        final floorIndex = location.floors.keys.first;
        final routableTargetCenter = location.centerPoints[floorIndex];
        if (routableTargetCenter == null) {
          return null; // Skip if no center point for the floor
        }

        final company = await _companyFromRoutableTarget(location);

        // Use buildingId from location for clustering
        final buildingId = location.buildingId.toString();

        return MapLocation(
          id: FlutterNodeFloorIndex(
            nodeId: location.nodeId,
            floorIndex: floorIndex!,
          ),
          name: location.name,
          latitude: location.centerPoints[floorIndex]!.lat,
          longitude: location.centerPoints[floorIndex]!.lon,
          type: company == null ? LocationType.food : LocationType.booth,
          featureModelId: location.featureModelId,
          imageUrl: company?.fullLogoUrl,
          companyId: company?.id,
          building: buildingId,
        );
      }).toList();

      final mappedLocations = await Future.wait(mappedLocationsFutures);

      return Result.success(mappedLocations.whereType<MapLocation>().toList());
    } catch (e) {
      return Result.failure(UnknownError('Failed to load locations: $e'));
    }
  }

  @override
  Future<Result<List<MapLocation>>> getLocationsByType(
    LocationType type,
  ) async {
    // Placeholder implementation
    return Result.success(<MapLocation>[]);
  }

  MapBuilding _getStudyC() {
    final floor2 = MapFloor(
      index: 0,
      name: '0',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711841, lon: 13.208909),
        NE: FlutterPointLLA(lat: 55.711841, lon: 13.209939),
        SW: FlutterPointLLA(lat: 55.711239, lon: 13.208909),
        image: const AssetImage('assets/images/map/sc_2.png'),
      ),
    );

    final floor1 = MapFloor(
      index: 1,
      name: '1',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711847, lon: 13.208934),
        NE: FlutterPointLLA(lat: 55.711847, lon: 13.210018),
        SW: FlutterPointLLA(lat: 55.711213, lon: 13.208934),
        image: const AssetImage('assets/images/map/sc_1.png'),
      ),
    );
    return MapBuilding(
      id: studyCBuildingId,
      name: 'Studie C',
      floors: [floor2],
      defaultFloorIndex: 0,
    );
  }

  MapBuilding _getGuildHouse() {
    final floorBasement = MapFloor(
      index: 0,
      name: '1',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.712775, lon: 13.208627),
        NE: FlutterPointLLA(lat: 55.712775, lon: 13.209831),
        SW: FlutterPointLLA(lat: 55.712071, lon: 13.208627),
        image: const AssetImage('assets/images/map/kh_1.png'),
      ),
    );
    final floor1 = MapFloor(
      index: 1,
      name: '1',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.712706, lon: 13.208546),
        NE: FlutterPointLLA(lat: 55.71271, lon: 13.20969),
        SW: FlutterPointLLA(lat: 55.712038, lon: 13.208554),
        image: const AssetImage('assets/images/map/kh_2.png'),
      ),
    );

    return MapBuilding(
      id: guildHouseBuildingId,
      name: 'Kårhuset',
      floors: [floorBasement, floor1],
      defaultFloorIndex: 0,
    );
  }

  MapBuilding _getEHouse() {
    final floor1 = MapFloor(
      index: 0,
      name: '1',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711453, lon: 13.209716),
        NE: FlutterPointLLA(lat: 55.711453, lon: 13.211027),
        SW: FlutterPointLLA(lat: 55.71069, lon: 13.209716),
        image: const AssetImage('assets/images/map/ehouse.png'),
      ),
    );
    return MapBuilding(
      id: eHouseBuildingId,
      name: 'E-huset',
      floors: [floor1],
      defaultFloorIndex: 0,
    );
  }

  @override
  List<MapBuilding> getMapBuildings() {
    return [_getStudyC(), _getGuildHouse(), _getEHouse()];
  }

  @override
  Future<Set<GroundOverlay>> getGroundOverlays(
    ImageConfiguration imageConfig,
  ) async {
    final buildings = getMapBuildings();
    final overlays = <GroundOverlay>{};

    for (final building in buildings) {
      // Use the default floor for each building
      final defaultFloor = building.floors.firstWhere(
        (floor) => floor.index == building.defaultFloorIndex,
        orElse: () => building.floors.first,
      );

      final floorMap = defaultFloor.map;

      // Create AssetMapBitmap for ground overlay with required bitmapScaling
      final mapBitmap = await AssetMapBitmap.create(
        imageConfig,
        (floorMap.image as AssetImage).assetName,
        bitmapScaling: MapBitmapScaling.none,
      );

      overlays.add(
        GroundOverlay.fromBounds(
          groundOverlayId: GroundOverlayId(
            'building_${building.id}_floor_${defaultFloor.index}',
          ),
          image: mapBitmap,
          bounds: LatLngBounds(
            southwest: LatLng(floorMap.SW.lat, floorMap.SW.lon),
            northeast: LatLng(floorMap.NE.lat, floorMap.NE.lon),
          ),
          transparency: 0,
        ),
      );
    }

    return overlays;
  }
}
