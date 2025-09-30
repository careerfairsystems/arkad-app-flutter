import 'package:flutter/material.dart';

import '../../domain/entities/map_building.dart';
import '../../domain/repositories/map_repository.dart';

/// ViewModel for managing map state and operations
class MapViewModel extends ChangeNotifier {
  final MapRepository _mapRepository;

  MapViewModel({required MapRepository mapRepository})
    : _mapRepository = mapRepository;

  // State
  List<MapBuilding> _buildings = [];

  // Getters
  List<MapBuilding> get buildings => _buildings;

  /// Load all buildings
  void loadBuildings() {
    _buildings = _mapRepository.getAllBuildings();
    notifyListeners();
  }
}
