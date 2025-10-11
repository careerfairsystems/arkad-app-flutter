import 'dart:ui' as ui;

import 'package:arkad/features/map/presentation/providers/location_provider.dart';
import 'package:arkad/shared/presentation/themes/arkad_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

/*
* final studieCCluster = Cluster( ClusterManagerId("261376248"),
  bounds: LatLngBounds(
    southwest: LatLng(55.711213, 13.208934),
    northeast: LatLng(55.711847, 13.210018),
  ),
  position: LatLng(
 55.711532,
13.209428,
  )
);

* */

const studieCCluster = ClusterManager(
  clusterManagerId: ClusterManagerId("261376248"),
);
const eHouseCluster = ClusterManager(
  clusterManagerId: ClusterManagerId("261376246"),
);
const khCluster = ClusterManager(clusterManagerId: ClusterManagerId("1834"));

// User location dot size in pixels
const double _userLocationDotSize = 20.0;

class ArkadMapWidget extends StatefulWidget {
  const ArkadMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.groundOverlays = const {},
    this.onMapCreated,
    this.onTap,
    this.minZoom = 18.0,
    this.maxZoom = 22.0,
    this.mapStylePath = 'assets/map_styles/arkad_dark_map_style.json',
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<GroundOverlay> groundOverlays;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
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
  int _selectedFloorIndex = 0;
  BitmapDescriptor? _userLocationIcon;
  bool _isSnappedToLocation = true;
  bool _isProgrammaticMove = false;
  LatLngBounds _allowedBounds = LatLngBounds(
    southwest: const LatLng(55.709214600107245, 13.207789044872932),
    northeast: const LatLng(55.713562876300905, 13.212897763941944),
  );

  @override
  void initState() {
    super.initState();
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

          // Center on user location if requested
          if (locationProvider.currentLocation != null) {
            _centerOnUserLocation(locationProvider.currentLocation!.latLng);
          }
        }
      } else if (locationProvider.hasPermission) {
        await locationProvider.startTracking();
      }
    });
  }

  void _onLocationChanged() {
    if (!_isSnappedToLocation) return;

    final locationProvider = Provider.of<LocationProvider>(
      context,
      listen: false,
    );

    if (locationProvider.currentLocation != null) {
      _centerOnUserLocation(locationProvider.currentLocation!.latLng);
    }
  }

  void _centerOnUserLocation(LatLng position) {
    _isProgrammaticMove = true;
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 20.0));
  }

  Set<Marker> _buildMarkers(LocationProvider? locationProvider) {
    final markers = Set<Marker>.from(widget.markers);

    // Add user location marker if icon is loaded and location is available
    if (_userLocationIcon != null &&
        locationProvider != null &&
        locationProvider.currentLocation != null) {
      final userLocation = locationProvider.currentLocation!;

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
        final availableFloors =
            locationProvider.currentLocation?.availableFloors ?? [];

        return Stack(
          children: [
            _buildGoogleMap(
              _buildMarkers(locationProvider),
              widget.groundOverlays,
            ),
            // Floor selector if floors are available
            if (availableFloors.length > 1)
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: _buildFloorSelector(availableFloors),
              ),
            // Location snap button
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

  Widget _buildFloorSelector(
    List<(int floorIndex, String floorLabel)> availableFloors,
  ) {
    // Set initial floor to first available floor if not already set
    if (_selectedFloorIndex == 0 && availableFloors.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedFloorIndex = availableFloors.first.$1;
          });
        }
      });
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: availableFloors.map((floor) {
          final isSelected = floor.$1 == _selectedFloorIndex;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFloorIndex = floor.$1;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00D9FF)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(17),
              ),
              child: Text(
                floor.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
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
    setState(() {
      _isSnappedToLocation = !_isSnappedToLocation;
    });

    if (_isSnappedToLocation) {
      // Snap to current location immediately
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      if (locationProvider.currentLocation != null) {
        _centerOnUserLocation(locationProvider.currentLocation!.latLng);
      }
    }
  }

  Widget _buildGoogleMap(
    Set<Marker> markers,
    Set<GroundOverlay> groundOverlays,
  ) {
    return GoogleMap(
      clusterManagers: {studieCCluster, eHouseCluster, khCluster},
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
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
      cameraTargetBounds: CameraTargetBounds(_allowedBounds),
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

  void _onCameraMove(CameraPosition position) {}

  void _onCameraIdle() {
    // Reset programmatic move flag after camera movement completes
    _isProgrammaticMove = false;
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
