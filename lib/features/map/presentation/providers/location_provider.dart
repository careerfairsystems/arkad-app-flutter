import 'dart:async';

import 'package:arkad/features/map/data/repositories/map_repository_impl.dart';
import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Provider for managing user location state
class LocationProvider extends ChangeNotifier {
  LocationProvider(this._repository);

  final LocationRepository _repository;

  final combainSDK = GetIt.I<FlutterCombainSDK>();

  UserLocation? _currentLocation;
  bool _hasPermission = false;
  String? _error;
  StreamSubscription<UserLocation>? _locationSubscription;

  UserLocation? get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;
  String? get error => _error;

  List<(int floorIndex, String floorLabel)> _availableFloorsFromLocation(
    FlutterCombainIndoorLocation? loc,
  ) {
    if (loc == null) return [];
    switch (loc.buildingId) {
      case MapRepositoryImpl.eHouseBuildingId:
        return [(0, '1')];
      case MapRepositoryImpl.studyCBuildingId:
        return [(0, '0')];
      case MapRepositoryImpl.guildHouseBuildingId:
        return [(0, 'Gasque'), (1, 'Entrance')];
      default:
        return [];
    }
  }

  void _handleCombainLocation() async {
    final loc = combainSDK.currentLocation.value;

    if (loc != null) {
      final snappedLocation = (await combainSDK.snapToFeatureModel(loc));
      print("Snapped location: $snappedLocation");
      final lat = snappedLocation?.lat ?? loc.latitude;
      final lon = snappedLocation?.lon ?? loc.longitude;

      _currentLocation = UserLocation(
        latLng: LatLng(lat, lon),
        accuracy: loc.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(loc.fetchedTimeMillis),
        floorIndex: loc.indoor?.floorIndex,
        availableFloors: _availableFloorsFromLocation(loc.indoor),
      );
      notifyListeners();
    }
  }

  /// Initialize location provider (check permissions and service)
  Future<void> initialize() async {
    _hasPermission = await _repository.hasLocationPermission();
    combainSDK.currentLocation.addListener(() {
      _handleCombainLocation();
    });
    notifyListeners();
  }

  /// Request location permission
  Future<bool> requestPermission() async {
    _error = null;
    final granted = await _repository.requestLocationPermission();
    _hasPermission = granted;

    if (!granted) {
      _error = 'Location permission denied';
    }

    notifyListeners();
    return granted;
  }

  /// Start tracking location updates
  Future<void> startTracking() async {
    if (!_hasPermission) {
      _error = 'Location permission not granted';
      notifyListeners();
      return;
    }

    await combainSDK.start();
  }

  /// Stop tracking location updates
  void stopTracking() {
    combainSDK.stop();
  }

  /// Update floor information manually (for indoor positioning)
  void updateFloor(int floorIndex) {
    /**
     * TODO: Implement logic to switch floor
     * When switching the new floor should be used until building changes
     */
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }
}
