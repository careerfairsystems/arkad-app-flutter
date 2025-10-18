import 'dart:async';

import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:arkad/features/map/domain/repositories/map_repository.dart';
import 'package:arkad/services/env.dart';
import 'package:arkad/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:flutter_combainsdk/pigeon_extensions.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

LatLngBounds allowedBounds = LatLngBounds(
  southwest: const LatLng(55.709214600107245, 13.207789044872932),
  northeast: const LatLng(55.713562876300905, 13.212897763941944),
);

bool isLocationInBounds(LatLng location) {
  return location.latitude >= allowedBounds.southwest.latitude &&
      location.latitude <= allowedBounds.northeast.latitude &&
      location.longitude >= allowedBounds.southwest.longitude &&
      location.longitude <= allowedBounds.northeast.longitude;
}

/// Provider for managing user location state
class LocationProvider extends ChangeNotifier {
  LocationProvider(this._repository, this._mapRepository);

  final LocationRepository _repository;
  final MapRepository _mapRepository;

  final combainSDK = GetIt.I<FlutterCombainSDK>();
  final env = GetIt.I<Env>();

  UserLocation? _currentLocation;
  bool _hasPermission = false;
  String? _error;
  StreamSubscription<UserLocation>? _locationSubscription;

  UserLocation? get currentLocation => _currentLocation;
  bool get hasPermission => _hasPermission;
  String? get error => _error;

  String? _buildingNameFromLocation(FlutterCombainIndoorLocation? loc) {
    if (loc == null) return null;
    return _mapRepository.getBuildingName(loc.buildingId);
  }

  String? _floorLabelFromLocation(FlutterCombainIndoorLocation? loc) {
    if (loc == null || loc.floorIndex == null) return null;
    return _mapRepository.getFloorLabel(loc.buildingId, loc.floorIndex!);
  }

  void _handleCombainLocation() async {
    final loc = combainSDK.currentLocation.value;

    if (loc != null) {
      final snappedLocation = (await combainSDK.snapToFeatureModel(loc));
      print("Snapped location: ${snappedLocation?.toStringPretty()}");
      print("Original location: ${loc.toStringPretty()}");
      final lat = snappedLocation?.lat ?? loc.latitude;
      final lon = snappedLocation?.lon ?? loc.longitude;
      final latLng = LatLng(lat, lon);
      if (!isLocationInBounds(latLng)) {
        print("Location out of bounds: $latLng");
        _currentLocation = null;
        notifyListeners();
        return;
      }

      _currentLocation = UserLocation(
        latLng: latLng,
        accuracy: loc.accuracy,
        buildingId: loc.indoor?.buildingId,
        timestamp: DateTime.fromMillisecondsSinceEpoch(loc.fetchedTimeMillis),
        floorIndex: loc.indoor?.floorIndex,
        floorLabel: _floorLabelFromLocation(loc.indoor),
        buildingName: _buildingNameFromLocation(loc.indoor),
      );
      await _repository.captureLocation(loc);
      notifyListeners();
    } else {
      _currentLocation = null;
      notifyListeners();
    }
  }

  /// Initialize location provider (check permissions and service)
  Future<void> initialize() async {
    _hasPermission = await _repository.hasLocationPermission();
    combainSDK.currentLocation.addListener(() {
      _handleCombainLocation();
    });
    _handleCombainLocation();
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
