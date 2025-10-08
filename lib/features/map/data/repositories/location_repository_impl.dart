import 'package:arkad/features/map/data/data_sources/location_data_source.dart';
import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:arkad/shared/domain/result.dart';

/// Implementation of LocationRepository using LocationDataSource
class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl(this._dataSource);

  final LocationDataSource _dataSource;

  @override
  Future<Result<UserLocation>> getCurrentLocation() async {
    try {
      final location = await _dataSource.getCurrentPosition();
      return Result.success(location);
    } catch (e) {
      return Result.failure(
        Exception('Failed to get current location: $e') as Never,
      );
    }
  }

  @override
  Stream<UserLocation> get locationStream => _dataSource.getPositionStream();

  @override
  Future<bool> hasLocationPermission() async {
    return await _dataSource.hasPermission();
  }

  @override
  Future<bool> requestLocationPermission() async {
    return await _dataSource.requestPermission();
  }

  @override
  Future<bool> isLocationServiceEnabled() async {
    return await _dataSource.isServiceEnabled();
  }
}
