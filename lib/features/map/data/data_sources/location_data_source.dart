import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Data source for location services using Geolocator
class LocationDataSource {
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Minimum distance (in meters) before update
  );

  /// Get current position
  Future<UserLocation> getCurrentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: _locationSettings,
    );

    return _mapPositionToUserLocation(position);
  }

  /// Stream of position updates
  Stream<UserLocation> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).map(_mapPositionToUserLocation);
  }

  /// Check if location permission is granted
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled
  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Map Geolocator Position to UserLocation entity
  UserLocation _mapPositionToUserLocation(Position position) {
    return UserLocation(
      latLng: LatLng(position.latitude, position.longitude),
      accuracy: position.accuracy,
      timestamp: position.timestamp,
      heading: position.heading,
      speed: position.speed,
      floorIndex:
          null, // Floor detection can be added later (requires indoor positioning)
    );
  }
}
