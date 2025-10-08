import 'package:google_maps_flutter/google_maps_flutter.dart';

/// User's current location with metadata and floor information
class UserLocation {
  const UserLocation({
    required this.latLng,
    required this.accuracy,
    required this.timestamp,
    this.heading,
    this.speed,
    this.floorIndex,
    this.availableFloors = const [],
  });

  final LatLng latLng;
  final double accuracy; // In meters
  final DateTime timestamp;
  final double? heading; // Direction in degrees
  final double? speed; // Speed in m/s
  final int? floorIndex;
  final List<(int floorIndex, String floorLabel)>
  availableFloors; // List of available floors at this location

  @override
  String toString() =>
      'UserLocation(lat: ${latLng.latitude}, lng: ${latLng.longitude}, accuracy: ${accuracy}m, floorIndex: ${floorIndex ?? "unknown"}, availableFloors: ${availableFloors.length})';
}
