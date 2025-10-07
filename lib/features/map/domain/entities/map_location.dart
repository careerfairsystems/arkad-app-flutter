import 'package:flutter_combainsdk/messages.g.dart';

/// Domain entity representing a location on the map
class MapLocation {
  final FlutterNodeFloorIndex id;
  final String name;
  final double latitude;
  final double longitude;
  final LocationType type;
  final String? imageUrl;
  final int? companyId;

  const MapLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.imageUrl,
    this.companyId,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapLocation && other.id == id;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, latitude, longitude, type);
  }

  @override
  String toString() {
    return 'MapLocation(id: $id, name: $name, type: $type)';
  }
}

/// Types of locations on the map
enum LocationType {
  booth,
  food;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case LocationType.booth:
        return 'Company Booth';
      case LocationType.food:
        return 'Food & Drinks';
    }
  }
}
