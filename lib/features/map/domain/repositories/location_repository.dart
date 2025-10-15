import 'package:flutter_combainsdk/messages.g.dart';

/// Repository for accessing user location data
abstract class LocationRepository {
  /// Capture user location
  Future<void> captureLocation(FlutterCombainLocation location);

  /// Check if location permission is granted
  Future<bool> hasLocationPermission();

  /// Request location permission
  Future<bool> requestLocationPermission();
}
