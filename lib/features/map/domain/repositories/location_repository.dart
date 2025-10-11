/// Repository for accessing user location data
abstract class LocationRepository {
  /// Check if location permission is granted
  Future<bool> hasLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();
}
