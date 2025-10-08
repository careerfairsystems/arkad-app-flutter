import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reusable Google Maps widget with Arkad dark theme styling
///
/// Provides a pre-configured Google Maps instance with:
/// - Custom dark theme map style
/// - Configurable markers and camera position
/// - Zoom restrictions
/// - My location support
/// - Ground overlays for floor maps
class ArkadMapWidget extends StatefulWidget {
  const ArkadMapWidget({
    super.key,
    required this.initialCameraPosition,
    required this.markers,
    this.groundOverlays = const {},
    this.onMapCreated,
    this.onTap,
    this.minZoom = 12.0,
    this.maxZoom = 18.0,
    this.myLocationEnabled = true,
    this.mapStylePath = 'assets/map_styles/arkad_dark_map_style.json',
  });

  final CameraPosition initialCameraPosition;
  final Set<Marker> markers;
  final Set<GroundOverlay> groundOverlays;
  final void Function(GoogleMapController)? onMapCreated;
  final void Function(LatLng)? onTap;
  final double minZoom;
  final double maxZoom;
  final bool myLocationEnabled;
  final String mapStylePath;

  @override
  State<ArkadMapWidget> createState() => _ArkadMapWidgetState();
}

class _ArkadMapWidgetState extends State<ArkadMapWidget> {
  GoogleMapController? _mapController;
  String? _mapStyle;

  @override
  void initState() {
    super.initState();
    _loadMapStyle();
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

  @override
  Widget build(BuildContext context) {
    print("Ground layers: ${widget.groundOverlays}");
    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        widget.onMapCreated?.call(controller);
      },
      style: _mapStyle,
      initialCameraPosition: widget.initialCameraPosition,
      markers: widget.markers,
      groundOverlays: widget.groundOverlays,
      scrollGesturesEnabled: true, // Enables panning
      zoomGesturesEnabled: true, // Enables pinch-to-zoom
      tiltGesturesEnabled: true, // Enables tilt gestures
      rotateGesturesEnabled: true, // Enables rotation

      minMaxZoomPreference: MinMaxZoomPreference(
        widget.minZoom,
        widget.maxZoom,
      ),
      onTap: widget.onTap,
      myLocationEnabled: widget.myLocationEnabled,
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
