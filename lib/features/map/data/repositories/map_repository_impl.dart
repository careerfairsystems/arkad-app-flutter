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
            FlutterPaginationOptions(page: 0, pageSize: 200),
          );

      // Map over locations and await all futures
      final mappedLocationsFutures = locations.map((location) async {
        final floorIndex = location.floors.keys.first;
        final company = await _companyFromRoutableTarget(location);
        return MapLocation(
          id: FlutterNodeFloorIndex(
            nodeId: location.nodeId,
            floorIndex: floorIndex!,
          ),
          name: location.name,
          latitude: location.centerPoints[floorIndex]!.lat,
          longitude: location.centerPoints[floorIndex]!.lon,
          type: company == null ? LocationType.food : LocationType.booth,
          imageUrl: company?.fullLogoUrl,
          companyId: company?.id,
        );
      }).toList();

      final mappedLocations = await Future.wait(mappedLocationsFutures);

      return Result.success(mappedLocations);
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
      id: 1,
      name: 'Studie C',
      floors: [floor2],
      defaultFloorIndex: 0,
    );
  }

  MapBuilding _getGuildHouse() {
    final floorBasement = MapFloor(
      index: -1,
      name: 'B',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711004, lon: 13.210634),
        NE: FlutterPointLLA(lat: 55.711004, lon: 13.211712),
        SW: FlutterPointLLA(lat: 55.710942, lon: 13.210634),
        image: const AssetImage('assets/images/map/gh_b.png'),
      ),
    );
    final floor1 = MapFloor(
      index: 0,
      name: '0',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711569, lon: 13.210634),
        NE: FlutterPointLLA(lat: 55.711569, lon: 13.211712),
        SW: FlutterPointLLA(lat: 55.710942, lon: 13.210634),
        image: const AssetImage('assets/images/map/gh_1.png'),
      ),
    );
    final floor2 = MapFloor(
      index: 1,
      name: '1',
      map: FloorMap(
        topLeft: FlutterPointLLA(lat: 55.711569, lon: 13.210634),
        NE: FlutterPointLLA(lat: 55.711569, lon: 13.211712),
        SW: FlutterPointLLA(lat: 55.710942, lon: 13.210634),
        image: const AssetImage('assets/images/map/gh_2.png'),
      ),
    );

    return MapBuilding(
      id: 2,
      name: 'Guild House',
      floors: [floorBasement, floor1, floor2],
      defaultFloorIndex: 0,
    );
  }

  @override
  List<MapBuilding> getMapBuildings() {
    return [_getStudyC()];
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
