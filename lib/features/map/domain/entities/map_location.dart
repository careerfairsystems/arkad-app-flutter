import 'package:arkad/features/map/domain/entities/map_building.dart';

/// Domain entity representing a location on the map
class MapLocation {
  final int id;
  final String name;
  final String description;
  final Point position;
  final LocationType type;
  final String? imageUrl;

  const MapLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.position,
    this.imageUrl,
  });

  /// Create a copy with updated values
  MapLocation copyWith({
    int? id,
    String? name,
    String? description,
    Point? position,
    LocationType? type,
    String? imageUrl,
  }) {
    return MapLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      position: position ?? this.position,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapLocation &&
        other.id == id &&
        other.name == name &&
        other.position.latitude == position.latitude &&
        other.position.longitude == position.longitude &&
        other.type == type;
  }

  @override
  int get hashCode {
    return Object.hash(id, name, position.latitude, position.longitude, type);
  }

  @override
  String toString() {
    return 'MapLocation(id: $id, name: $name, type: $type)';
  }
}

/// Types of locations on the map
enum LocationType {
  venue,
  booth,
  facility,
  emergency,
  food,
  parking;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case LocationType.venue:
        return 'Venue';
      case LocationType.booth:
        return 'Company Booth';
      case LocationType.facility:
        return 'Facility';
      case LocationType.emergency:
        return 'Emergency';
      case LocationType.food:
        return 'Food & Drinks';
      case LocationType.parking:
        return 'Parking';
    }
  }
}
