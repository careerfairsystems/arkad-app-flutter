import 'dart:async';

import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:flutter/foundation.dart';

/// Provider for managing user location state
class LocationProvider extends ChangeNotifier {
  LocationProvider(this._repository);

  final LocationRepository _repository;

  UserLocation? _currentLocation;
  bool _isTracking = false;
  bool _hasPermission = false;
  bool _isServiceEnabled = false;
  String? _error;
  StreamSubscription<UserLocation>? _locationSubscription;

  UserLocation? get currentLocation => _currentLocation;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  bool get isServiceEnabled => _isServiceEnabled;
  String? get error => _error;

  /// Initialize location provider (check permissions and service)
  Future<void> initialize() async {
    _hasPermission = await _repository.hasLocationPermission();
    _isServiceEnabled = await _repository.isLocationServiceEnabled();
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

  /// Get current location once
  Future<void> getCurrentLocation() async {
    _error = null;

    if (!_hasPermission) {
      _error = 'Location permission not granted';
      notifyListeners();
      return;
    }

    if (!_isServiceEnabled) {
      _error = 'Location service is disabled';
      notifyListeners();
      return;
    }

    final result = await _repository.getCurrentLocation();
    result.when(
      success: (location) {
        _currentLocation = location;
        _error = null;
      },
      failure: (error) {
        _error = error.toString();
      },
    );

    notifyListeners();
  }

  /// Start tracking location updates
  Future<void> startTracking() async {
    if (_isTracking) return;

    if (!_hasPermission) {
      _error = 'Location permission not granted';
      notifyListeners();
      return;
    }

    if (!_isServiceEnabled) {
      _error = 'Location service is disabled';
      notifyListeners();
      return;
    }

    _isTracking = true;
    _error = null;
    notifyListeners();

    _locationSubscription = _repository.locationStream.listen(
      (location) {
        _currentLocation = location;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        _isTracking = false;
        notifyListeners();
      },
    );
  }

  /// Stop tracking location updates
  void stopTracking() {
    if (!_isTracking) return;

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Update floor information manually (for indoor positioning)
  void updateFloor(int floorIndex) {
    if (_currentLocation == null) return;

    _currentLocation = UserLocation(
      latLng: _currentLocation!.latLng,
      accuracy: _currentLocation!.accuracy,
      timestamp: _currentLocation!.timestamp,
      heading: _currentLocation!.heading,
      speed: _currentLocation!.speed,
      floorIndex: floorIndex,
      availableFloors: _currentLocation!.availableFloors,
    );

    notifyListeners();
  }

  /// Update available floors for current location
  void updateAvailableFloors(List<(int floorIndex, String floorLabel)> floors) {
    if (_currentLocation == null) return;

    _currentLocation = UserLocation(
      latLng: _currentLocation!.latLng,
      accuracy: _currentLocation!.accuracy,
      timestamp: _currentLocation!.timestamp,
      heading: _currentLocation!.heading,
      speed: _currentLocation!.speed,
      floorIndex: _currentLocation!.floorIndex,
      availableFloors: floors,
    );

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
