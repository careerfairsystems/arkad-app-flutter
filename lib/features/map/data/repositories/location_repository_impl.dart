import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:geolocator/geolocator.dart';

/// Implementation of LocationRepository using LocationDataSource
class LocationRepositoryImpl implements LocationRepository {
  @override
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
