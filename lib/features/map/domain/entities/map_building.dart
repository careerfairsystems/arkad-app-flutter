import 'package:flutter/material.dart';

class Point {
  final double latitude;
  final double longitude;

  Point({required this.latitude, required this.longitude});
}

class MapFloor {
  Point NE;
  Point SW;
  Point topLeft;
  int floorNumber;
  final String image;

  MapFloor({
    required this.NE,
    required this.SW,
    required this.topLeft,
    required this.floorNumber,
    required this.image,
  });
}

class MapBuilding {
  final String name;
  final String combainId;
  final Point markerPosition;
  final List<MapFloor> floors;

  MapBuilding({
    required this.name,
    required this.combainId,
    required this.markerPosition,
    required this.floors,
  });
}
