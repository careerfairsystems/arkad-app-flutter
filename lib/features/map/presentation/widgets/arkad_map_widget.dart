import 'package:arkad/features/map/presentation/providers/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

/// Reusable Google Maps widget with Arkad dark theme styling and location tracking
///
/// Provides a pre-configured Google Maps instance with:
/// - Custom dark theme map style
/// - Configurable markers and camera position
/// - Zoom restrictions
/// - Custom location provider integration
/// - Ground overlays for floor maps
/// - Automatic location tracking with floor information
class ArkadMapWidget extends StatefulWidget {
  const ArkadMapWidget({
    super.key,
    required this.initialCameraPosition,
    this.markers = const {},
    this.groundOverlays = const {},
    this.availableFloors = const [],
    this.onMapCreated,
    this.onTap,
    this.minZoom = 12.0,
    this.maxZoom = 18.0,
    this.enableLocationTracking = false,
    this.showUserLocationMarker = false,
    this.centerOnUserLocation = false,
    this.mapStylePath = 'assets/map_styles/arkad_dark_map_style.json',
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<GroundOverlay> groundOverlays;
  final List<(int floorIndex, String floorLabel)> availableFloors;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final double minZoom;
  final double maxZoom;
  final bool enableLocationTracking;
  final bool showUserLocationMarker;
  final bool centerOnUserLocation;
  final String mapStylePath;

  @override
  State<ArkadMapWidget> createState() => _ArkadMapWidgetState();
}

class _ArkadMapWidgetState extends State<ArkadMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;
  bool _hasRequestedPermission = false;
  int _selectedFloorIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
    _initializeLocationTracking();

    // Set initial floor to first available floor
    if (widget.availableFloors.isNotEmpty) {
      _selectedFloorIndex = widget.availableFloors.first.$1;
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
    if (!widget.enableLocationTracking) return;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );

      // Initialize location provider
      await locationProvider.initialize();

      if (widget.enableLocationTracking) {
        // Request permission if needed
        if (!locationProvider.hasPermission && !_hasRequestedPermission) {
          _hasRequestedPermission = true;
          final granted = await locationProvider.requestPermission();

          if (granted) {
            await locationProvider.startTracking();

            // Center on user location if requested
            if (widget.centerOnUserLocation &&
                locationProvider.currentLocation != null) {
              _centerOnUserLocation(locationProvider.currentLocation!.latLng);
            }
          }
        } else if (locationProvider.hasPermission) {
          await locationProvider.startTracking();
        }
      }
    });
  }

  void _centerOnUserLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 16.0));
  }

  Set<Marker> _buildMarkers(LocationProvider? locationProvider) {
    final markers = Set<Marker>.from(widget.markers);

    // Add user location marker if enabled and location is available
    if (widget.showUserLocationMarker &&
        locationProvider != null &&
        locationProvider.currentLocation != null) {
      final userLocation = locationProvider.currentLocation!;

      // Find floor label from available floors
      String? floorLabel;
      if (userLocation.floorIndex != null &&
          userLocation.availableFloors.isNotEmpty) {
        final floor = userLocation.availableFloors.firstWhere(
          (f) => f.$1 == userLocation.floorIndex,
          orElse: () =>
              (userLocation.floorIndex!, 'Floor ${userLocation.floorIndex}'),
        );
        floorLabel = floor.$2;
      }

      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLocation.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: floorLabel != null
                ? 'Floor: $floorLabel'
                : 'Accuracy: ${userLocation.accuracy.toStringAsFixed(1)}m',
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // Use Consumer if location tracking is enabled, otherwise build directly
    final mapWidget =
        widget.enableLocationTracking || widget.showUserLocationMarker
        ? Consumer<LocationProvider>(
            builder: (context, locationProvider, child) {
              return _buildGoogleMap(
                _buildMarkers(locationProvider),
                widget.groundOverlays,
              );
            },
          )
        : _buildGoogleMap(widget.markers, widget.groundOverlays);

    // Show floor selector if floors are available
    if (widget.availableFloors.length > 1) {
      return Stack(
        children: [
          mapWidget,
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: _buildFloorSelector(),
          ),
        ],
      );
    }

    return mapWidget;
  }

  Widget _buildFloorSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F2E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: widget.availableFloors.map((floor) {
          final isSelected = floor.$1 == _selectedFloorIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFloorIndex = floor.$1;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF00D9FF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  floor.$2,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoogleMap(
    Set<Marker> markers,
    Set<GroundOverlay> groundOverlays,
  ) {
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      style: _mapStyle,
      initialCameraPosition: widget.initialCameraPosition,
      markers: markers,
      groundOverlays: groundOverlays,
      scrollGesturesEnabled: true, // Enables panning
      zoomGesturesEnabled: true, // Enables pinch-to-zoom
      tiltGesturesEnabled: true, // Enables tilt gestures
      rotateGesturesEnabled: true, // Enables rotation

      minMaxZoomPreference: MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      onTap: widget.onTap,
      myLocationEnabled: false, // Always false, we use custom location marker
    );
  }

  @override
  void dispose() {
    if (widget.enableLocationTracking) {
      final locationProvider = Provider.of<LocationProvider>(
        context,
        listen: false,
      );
      locationProvider.stopTracking();
    }
    _mapController?.dispose();
    super.dispose();
  }
}
