/// Domain entity representing a location on the map
class MapLocation {
  final int id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final LocationType type;
  final String? imageUrl;
  final Map<String, dynamic>? metadata;

  const MapLocation({
    required this.id,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.type,
    this.imageUrl,
    this.metadata,
  });

  /// Create a copy with updated values
  MapLocation copyWith({
    int? id,
    String? name,
    String? description,
    double? latitude,
    double? longitude,
    LocationType? type,
    String? imageUrl,
    Map<String, dynamic>? metadata,
  }) {
    return MapLocation(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      type: type ?? this.type,
      imageUrl: imageUrl ?? this.imageUrl,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MapLocation &&
        other.id == id &&
        other.name == name &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.type == type;
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
