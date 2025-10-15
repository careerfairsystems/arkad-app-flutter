import 'dart:ui' as ui;

import 'package:arkad/features/map/domain/entities/map_location.dart';
import 'package:arkad/features/map/domain/entities/user_location.dart';
import 'package:arkad/features/map/domain/repositories/map_repository.dart';
import 'package:arkad/features/map/presentation/providers/location_provider.dart';
import 'package:arkad/features/map/presentation/view_models/map_view_model.dart';
import 'package:arkad/features/map/presentation/widgets/floor_selector_widget.dart';
import 'package:arkad/services/service_locator.dart';
import 'package:arkad/shared/presentation/themes/arkad_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

// User location dot size in pixels
const double _userLocationDotSize = 20.0;
const double _searchBarOffset = 100.0;

class ArkadMapWidget extends StatefulWidget {
  const ArkadMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.onMapCreated,
    this.onTap,
    this.onBuildingChanged,
    this.onCameraMove,
    this.minZoom = 18.0,
    this.maxZoom = 22.0,
    this.mapStylePath = 'assets/map_styles/arkad_dark_map_style.json',
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final void Function(MapBuilding? building)? onBuildingChanged;
  final void Function(CameraPosition)? onCameraMove;
  final double minZoom;
  final double maxZoom;
  final String mapStylePath;

  @override
  State<ArkadMapWidget> createState() => _ArkadMapWidgetState();
}

class _ArkadMapWidgetState extends State<ArkadMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  bool _hasRequestedPermission = false;
  BitmapDescriptor? _userLocationIcon;
  bool _isSnappedToLocation =
      false; // Will be set to true only if location is in bounds
  bool _isProgrammaticMove = false;
  CameraPosition? _currentCameraPosition;
  MapBuilding? _currentFocusedBuilding;
  MapViewModel _mapViewModel = serviceLocator<MapViewModel>();

  @override
  void initState() {
    super.initState();
    _currentCameraPosition = widget.initialCameraPosition;
    _loadMapStyle();
    _createUserLocationIcon();
    _initializeLocationTracking();
  }

  Future<void> _createUserLocationIcon() async {
    const size = _userLocationDotSize;
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);

    // Draw white border circle
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(_userLocationDotSize / 2, _userLocationDotSize / 2),
      size / 2,
      borderPaint,
    );

    // Draw inner blue circle
    final fillPaint = Paint()
      ..color = ArkadColors.arkadLightTurkos
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      const Offset(_userLocationDotSize / 2, _userLocationDotSize / 2),
      (size / 2) - 2, // 2px white border
      fillPaint,
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    if (bytes != null && mounted) {
      final icon = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
      setState(() {
        _userLocationIcon = icon;
      });
    }
  }

  Future<void> _loadMapStyle() async {
    try {
      final String style = await rootBundle.loadString(widget.mapStylePath);
      if (mounted) {
        setState(() {
          _mapStyle = style;
        });
      }
    } catch (e) {
      // Map style loading failed, continue with default style
      debugPrint('Failed to load map style from ${widget.mapStylePath}: $e');
    }
  }

  void _initializeLocationTracking() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Initialize location provider
      await locationProvider.initialize();

      // Listen to location changes to follow when snapped
      locationProvider.addListener(_onLocationChanged);

      // Request permission if needed
      if (!locationProvider.hasPermission && !_hasRequestedPermission) {
        _hasRequestedPermission = true;
        final granted = await locationProvider.requestPermission();

        if (granted) {
          await locationProvider.startTracking();

          // Center on user location and enable snapping only if within bounds
          if (locationProvider.currentLocation != null) {
            setState(() {
              _isSnappedToLocation = true;
            });
            _centerOnUserLocation(locationProvider.currentLocation!);
          }
        }
      } else if (locationProvider.hasPermission) {
        await locationProvider.startTracking();

        // Enable snapping if location is available and within bounds
        if (locationProvider.currentLocation != null) {
          setState(() {
            _isSnappedToLocation = true;
          });
        }
      }
    });
  }

  void _onLocationChanged() {
    if (!_isSnappedToLocation) return;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Only follow location if it's within bounds
    if (locationProvider.currentLocation != null) {
      _centerOnUserLocation(locationProvider.currentLocation!);
    }
  }

  void _centerOnUserLocation(UserLocation position) {
    _isProgrammaticMove = true;
    final buildingId = position.buildingId;
    final floorIndex = position.floorIndex;
    if (buildingId != null && floorIndex != null) {
      _mapViewModel.updateBuildingFloor(buildingId, floorIndex);
    }
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position.latLng, 20.0),
    );
  }

  Set<Marker> _buildMarkers(LocationProvider? locationProvider) {
    final markers = Set<Marker>.from(widget.markers);

    // Add user location marker if icon is loaded and location is available
    if (_userLocationIcon != null &&
        locationProvider != null &&
        locationProvider.currentLocation != null) {
      final userLocation = locationProvider.currentLocation!;
      final floorIndex = userLocation.floorIndex;
      final buildingId = userLocation.buildingId;
      if (buildingId == null) {
        // Don't show user location if building is unknown
        return markers;
      }
      final okFloorIndex = _mapViewModel.getBuildingFloor(buildingId);
      if (floorIndex != okFloorIndex) {
        // Don't show user location if floor index doesn't match selected floor
        return markers;
      }

      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLocation.latLng,
          icon: _userLocationIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer to get location data for markers and available floors
    return Consumer<LocationProvider>(
      builder: (context, locationProvider, child) {
        final building = _currentFocusedBuilding;

        return Stack(
          children: [
            _buildGoogleMap(
              _buildMarkers(locationProvider),
              _mapViewModel.groundOverlays,
            ),
            // Floor selector if floors are available and building is identified
            if (building != null && building.floors.length > 1)
              Positioned(
                top: _searchBarOffset,
                left: 16,
                child: FloorSelectorWidget(building: building),
              ),
            // Current location widget - show if location exists
            if (locationProvider.currentLocation != null)
              Positioned(
                top: _searchBarOffset,
                right: 16,
                child: _buildCurrentLocationWidget(
                  locationProvider.currentLocation!,
                ),
              ),
            // Location snap button - only show if location exists and is in bounds
            if (locationProvider.currentLocation != null)
              Positioned(
                bottom: 16,
                right: 16,
                child: _buildLocationSnapButton(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentLocationWidget(UserLocation location) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Current Location',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${location.buildingName} - ${location.floorLabel}',
            style: const TextStyle(
              color: ArkadColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSnapButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleSnapToLocation,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              Icons.location_on,
              color: _isSnappedToLocation
                  ? ArkadColors.arkadLightTurkos
                  : Colors.grey,
              size: 28,
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSnapToLocation() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    // Only allow snapping if location exists and is within bounds
    if (!_isSnappedToLocation && locationProvider.currentLocation != null) {
      setState(() {
        _isSnappedToLocation = true;
      });
      _centerOnUserLocation(locationProvider.currentLocation!);
    } else {
      setState(() {
        _isSnappedToLocation = false;
      });
    }
  }

  Widget _buildGoogleMap(
    Set<Marker> markers,
    Set<GroundOverlay> groundOverlays,
  ) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) async {
        _mapController = controller;
        widget.onMapCreated?.call(controller);

        // Determine initial focused building
        if (_currentCameraPosition != null) {
          try {
            final visibleRegion = await controller.getVisibleRegion();
            _updateFocusedBuilding(visibleRegion, _currentCameraPosition!.zoom);
          } catch (e) {
            debugPrint('Failed to get initial visible region: $e');
          }
        }
      },
      style: _mapStyle,
      initialCameraPosition: widget.initialCameraPosition,
      markers: markers,
      groundOverlays: groundOverlays,
      tiltGesturesEnabled: false, // Enables tilt gestures
      rotateGesturesEnabled: false, // Enables rotation
      zoomControlsEnabled: false,

      minMaxZoomPreference: MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      onTap: widget.onTap,
      onCameraMove: _onCameraMove,
      onCameraMoveStarted: _onCameraMoveStarted,
      onCameraIdle: _onCameraIdle,
      cameraTargetBounds: CameraTargetBounds(allowedBounds),
    );
  }

  void _onCameraMoveStarted() {
    // If camera moves and it's not from our code, user is interacting
    if (!_isProgrammaticMove && _isSnappedToLocation) {
      setState(() {
        _isSnappedToLocation = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _currentCameraPosition = position;
    widget.onCameraMove?.call(position);
  }

  void _onCameraIdle() async {
    // Reset programmatic move flag after camera movement completes
    _isProgrammaticMove = false;

    // Update focused building based on camera position and zoom
    if (_mapController != null && _currentCameraPosition != null) {
      try {
        final visibleRegion = await _mapController!.getVisibleRegion();
        _updateFocusedBuilding(visibleRegion, _currentCameraPosition!.zoom);
      } catch (e) {
        debugPrint('Failed to get visible region: $e');
      }
    }
  }

  void _updateFocusedBuilding(LatLngBounds bounds, double zoom) {
    final mapRepository = serviceLocator<MapRepository>();

    MapBuilding? building;
    if (zoom > 19) {
      building = mapRepository.mostLikelyBuilding(bounds);
    }

    // Only update and notify if the focused building changed
    if (building != _currentFocusedBuilding) {
      _currentFocusedBuilding = building;
      widget.onBuildingChanged?.call(_currentFocusedBuilding);

      // Log the building change
      if (building != null) {
        Sentry.logger.info(
          'Focused building changed',
          attributes: {
            'building_id': SentryLogAttribute.string(building.id.toString()),
            'building_name': SentryLogAttribute.string(building.name),
            'zoom': SentryLogAttribute.string(zoom.toString()),
          },
        );
      } else if (_currentFocusedBuilding == null) {
        Sentry.logger.debug(
          'Focused building cleared',
          attributes: {'zoom': SentryLogAttribute.string(zoom.toString())},
        );
      }
    }
  }

  @override
  void dispose() {
    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );
    locationProvider.removeListener(_onLocationChanged);
    locationProvider.stopTracking();
    _mapController?.dispose();
    super.dispose();
  }
}
