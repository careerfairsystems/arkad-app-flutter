import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/shared/domain/result.dart';

/// Repository for accessing user location data
abstract class LocationRepository {
  /// Get the current user location
  Future<Result<UserLocation>> getCurrentLocation();

  /// Stream of location updates
  Stream<UserLocation> get locationStream;

  /// Check if location permission is granted
  Future<bool> hasLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled();
}
