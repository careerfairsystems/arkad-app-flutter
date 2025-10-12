import 'package:google_maps_flutter/google_maps_flutter.dart';

/// User's current location with metadata and floor information
class UserLocation {
  const UserLocation({
    required this.latLng,
    required this.accuracy,
    required this.timestamp,
    this.floorIndex,
    this.floorLabel,
    this.buildingName,
  });

  final LatLng latLng;
  final double accuracy; // In meters
  final DateTime timestamp;
  final int? floorIndex;
  final String? floorLabel;
  final String?
  buildingName; // Name of the building (e.g., "E-huset", "Studie C")

  @override
  String toString() =>
      'UserLocation(lat: ${latLng.latitude}, lng: ${latLng.longitude}, accuracy: ${accuracy}m, building: ${buildingName ?? "unknown"}, floorIndex: ${floorIndex ?? "unknown"}, floorLabel: ${floorLabel ?? "unknown"})';
}
