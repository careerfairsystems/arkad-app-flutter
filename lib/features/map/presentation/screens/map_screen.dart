import 'dart:ui' as ui;

import 'package:arkad/features/map/domain/repositories/map_repository.dart';
import 'package:arkad/services/combain_intializer.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/view_models/company_view_model.dart';
import '../../domain/entities/map_location.dart';
import '../view_models/map_permissions_view_model.dart';
import '../view_models/map_view_model.dart';
import '../widgets/arkad_map_widget.dart';
import '../widgets/company_info_card.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/permission_step_widget.dart';

/// Displays an interactive map of companies at ARKAD event
class MapScreen extends StatefulWidget {
  const MapScreen({super.key, this.preselectedCompanyId});

  final int? preselectedCompanyId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  Set<Marker> _markers = {};
  MapBuilding? currentFocusedBuilding;
  bool _shouldShowMarkers = false;
  double _currentZoom = 18.0;
  GoogleMapController? _mapController;
  final Map<int, BitmapDescriptor> _buildingMarkerIconCache = {};
  int? _previousSelectedCompanyId;
  bool _hasPostSDKInitialized = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
      final companyViewModel = Provider.of<CompanyViewModel>(
        context,
        listen: false,
      );
      final combainInitializer = Provider.of<CombainIntializer>(
        context,
        listen: false,
      );

      // Listen to map view model changes to update markers
      mapViewModel.addListener(_onMapViewModelChanged);

      // Listen to SDK initialization changes
      combainInitializer.addListener(_onSDKStateChanged);

      // Only load locations if SDK is initialized
      // Note: ViewModel also has this check, but we add it here for clarity
      if (combainInitializer.state.mapReady()) {
        _postSDKInitialization();
      } else {
        print(
          '[MapScreen] Skipping initial data load - SDK not initialized yet. '
          'Current state: ${combainInitializer.state}',
        );
      }

      // Load companies if not already loaded (for company info cards)
      if (!companyViewModel.isInitialized) {
        companyViewModel.loadCompanies();
      }
    });
  }

  void _onSDKStateChanged() {
    final combainInitializer = Provider.of<CombainIntializer>(
      context,
      listen: false,
    );

    if (combainInitializer.state.mapReady()) {
      _postSDKInitialization();
      combainInitializer.removeListener(_onSDKStateChanged);
    }
  }

  void _postSDKInitialization() {
    if (_hasPostSDKInitialized) return;
    _hasPostSDKInitialized = true;

    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);

    // Load locations, buildings, and ground overlays
    final imageConfig = createLocalImageConfiguration(context);
    mapViewModel.loadLocations().then((_) async {
      // Load ground overlays after buildings are loaded
      await mapViewModel.loadGroundOverlays(imageConfig);
      await _updateMarkers(mapViewModel.locations);

      // If a company was preselected (e.g., from company detail screen),
      // select it now that locations are loaded
      if (widget.preselectedCompanyId != null) {
        print(
          '[MapScreen] Selecting preselected company after locations loaded - '
          'company_id: ${widget.preselectedCompanyId}',
        );
        mapViewModel.selectCompany(widget.preselectedCompanyId);
      }
    });
  }

  void _onMapViewModelChanged() {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);

    // Update markers when locations change (after loading completes)
    if (!mapViewModel.isLoading && mapViewModel.locations.isNotEmpty) {
      _updateMarkers(mapViewModel.locations);
    }

    // Zoom to selected company location when selection changes
    if (mapViewModel.selectedCompanyId != null &&
        mapViewModel.selectedCompanyId != _previousSelectedCompanyId &&
        mapViewModel.selectedLocation != null &&
        _mapController != null) {
      print(
        '[MapScreen] Company selection changed, zooming to new location - '
        'company_id: ${mapViewModel.selectedCompanyId}, '
        'previous_company_id: ${_previousSelectedCompanyId ?? 'none'}, '
        'zoom_level: 22.0',
      );
      _previousSelectedCompanyId = mapViewModel.selectedCompanyId;
      final location = mapViewModel.selectedLocation!;
      _zoomToLocation(LatLng(location.latitude, location.longitude), 22.0);
    } else if (mapViewModel.selectedCompanyId == null) {
      // Clear tracking when selection is cleared
      print('[MapScreen] Company selection cleared');
      _previousSelectedCompanyId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArkadColors.arkadNavy,
      appBar: AppBar(
        backgroundColor: ArkadColors.arkadNavy,
        elevation: 0,
        title: Text(
          currentFocusedBuilding?.name ?? 'Map',
          style: const TextStyle(
            color: ArkadColors.white,
            fontSize: 18,
            fontFamily: 'MyriadProCondensed',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer<MapPermissionsViewModel>(
        builder: (context, permissionsViewModel, child) {
          // Show permission flow if not all permissions granted
          if (!permissionsViewModel.allPermissionsGranted) {
            return SafeArea(child: _buildPermissionFlow(permissionsViewModel));
          }

          // Permissions granted, now wait for SDK to start
          return Consumer<CombainIntializer>(
            builder: (context, combainInitializer, child) {
              // Show loading while Combain SDK is starting
              if (!combainInitializer.state.mapReady()) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: ArkadColors.arkadTurkos),
                      SizedBox(height: 16),
                      Text(
                        'Starting map services...',
                        style: TextStyle(
                          color: ArkadColors.white,
                          fontSize: 16,
                          fontFamily: 'MyriadProCondensed',
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Show map once SDK is started
              return _buildMapView();
            },
          );
        },
      ),
    );
  }

  Widget _buildMapView() {
    return Consumer2<MapViewModel, CompanyViewModel>(
      builder: (context, mapViewModel, companyViewModel, child) {
        // Get selected company from ViewModel
        final selectedCompany = mapViewModel.selectedCompanyId != null
            ? companyViewModel.getCompanyById(mapViewModel.selectedCompanyId!)
            : null;

        // Get building name and floor label from selected location
        final selectedLocation = mapViewModel.selectedLocation;
        String buildingName = 'Unknown';
        String floorLabel = 'Unknown Floor';

        if (selectedLocation != null) {
          // Find the floor label from the building
          final building = mapViewModel.buildings.firstWhere(
            (b) => b.id == selectedLocation.buildingId,
            orElse: () => mapViewModel.buildings.first,
          );
          buildingName = building.name;

          final floor = building.floors.firstWhere(
            (f) => f.index == selectedLocation.floorIndex,
            orElse: () => building.floors.first,
          );

          floorLabel = floor.name;
        }

        return Stack(
          children: [
            // Map
            ArkadMapWidget(
              initialCameraPosition: const CameraPosition(
                target: LatLng(
                  55.711469341726016,
                  13.209497337446173,
                ), // StudieC
                zoom: 18.0,
              ),
              onMapCreated: (controller) {
                _mapController = controller;

                // If a company is already selected (e.g., from company detail screen),
                // zoom to it now that the map is ready
                final mapViewModel = Provider.of<MapViewModel>(
                  context,
                  listen: false,
                );
                if (mapViewModel.selectedCompanyId != null &&
                    mapViewModel.selectedLocation != null) {
                  print(
                    '[MapScreen] Map created with pre-selected company, zooming to location - '
                    'company_id: ${mapViewModel.selectedCompanyId}, zoom_level: 22.0',
                  );
                  _previousSelectedCompanyId = mapViewModel.selectedCompanyId;
                  final location = mapViewModel.selectedLocation!;
                  _zoomToLocation(
                    LatLng(location.latitude, location.longitude),
                    22.0,
                  );
                }
              },
              markers: _markers,
              onTap: (_) {
                // Deselect company when tapping map
                if (selectedCompany != null) {
                  mapViewModel.clearSelection();
                }
              },
              onBuildingChanged: (building) {
                setState(() {
                  currentFocusedBuilding = building;
                });
              },
              onCameraMove: (position) {
                _onCameraMove(position);
              },
            ),

            // Search bar at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              child: MapSearchBar(
                onTap: _showSearchView,
                displayText: selectedCompany?.name,
              ),
            ),

            // Selected company info card at bottom
            if (selectedCompany != null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: CompanyInfoCard(
                  company: selectedCompany,
                  featureModelId: mapViewModel.selectedFeatureModelId,
                  buildingName: buildingName,
                  floorLabel: floorLabel,
                  onClose: () {
                    mapViewModel.clearSelection();
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPermissionFlow(MapPermissionsViewModel viewModel) {
    // Show loading while checking existing permissions
    if (viewModel.isCheckingPermissions || viewModel.currentStep == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: ArkadColors.arkadTurkos),
            SizedBox(height: 16),
            Text(
              'Checking permissions...',
              style: TextStyle(
                color: ArkadColors.white,
                fontSize: 16,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Main content
        Expanded(
          child: PermissionStepWidget(
            step: viewModel.currentStep!,
            onRequestPermission: () {
              viewModel.requestCurrentPermission();
            },
            onOpenSettings: () {
              viewModel.openSettings();
            },
            isLoading: viewModel.isRequestingPermission,
          ),
        ),

        // Page indicator
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(viewModel.steps.length, (index) {
              final isActive = index == viewModel.currentStepIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 12 : 8,
                height: isActive ? 12 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? ArkadColors.arkadTurkos : Colors.white38,
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Future<Marker> _companyMarker(MapLocation location) async {
    final companyViewModel = Provider.of<CompanyViewModel>(
      context,
      listen: false,
    );
    Company company = companyViewModel.getCompanyById(location.companyId!)!;
    final position = LatLng(location.latitude, location.longitude);

    // Try to get the company's logo, fallback to default marker if not available
    final icon =
        await company.getCompanyLogo(circular: true) ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);

    return Marker(
      markerId: MarkerId(location.companyId.toString()),
      position: position,
      onTap: () {
        final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
        mapViewModel.selectCompany(
          company.id,
          featureModelId: location.featureModelId,
        );
      },
      icon: icon,
      /*
      infoWindow: InfoWindow(
        title: location.name,
        snippet: location.type.displayName,
      ),
*/
    );
  }

  Future<void> _updateMarkers(List<MapLocation> locations) async {
    final newMarkers = <Marker>{};

    // Only show company markers if zoom > 20
    if (_shouldShowMarkers) {
      for (final location in locations) {
        if (location.companyId != null) {
          final marker = await _companyMarker(location);
          newMarkers.add(marker);
        }
      }
    } else {
      final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
      final repository = GetIt.I<MapRepository>();
      final companiesPerBuilding = await repository.getLocationsForBuilding();
      if (companiesPerBuilding.isFailure) {
        return;
      }

      for (final building in mapViewModel.buildings) {
        final companyCount =
            companiesPerBuilding.valueOrNull![building.id]?.length ?? 0;
        if (companyCount == 0) {
          continue;
        }

        final icon = await _buildingMarkerIcon(companyCount);
        final marker = Marker(
          markerId: MarkerId('building-${building.id}'),
          position: building.center,
          icon: icon,
          onTap: () {
            _zoomToLocation(building.center, 21.0);
          },
        );
        newMarkers.add(marker);
      }
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  Future<BitmapDescriptor> _buildingMarkerIcon(int count) async {
    final cachedIcon = _buildingMarkerIconCache[count];
    if (cachedIcon != null) {
      return cachedIcon;
    }

    const double size = 45;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size / 3, borderPaint);

    final fillPaint = Paint()
      ..color = ArkadColors.arkadTurkos
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, (size / 2) - 6, fillPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final textOffset = Offset(
      center.dx - (textPainter.width / 2),
      center.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, textOffset);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) {
      return BitmapDescriptor.defaultMarker;
    }

    final icon = BitmapDescriptor.bytes(bytes.buffer.asUint8List());
    _buildingMarkerIconCache[count] = icon;
    return icon;
  }

  void _showSearchView() {
    context.push('/map/search');
  }

  Future<void> _zoomToLocation(LatLng target, double zoom) async {
    final controller = _mapController;
    if (controller == null) {
      print('[MapScreen] Cannot zoom: map controller not initialized');
      return;
    }

    print(
      '[MapScreen] Animating camera to location - '
      'latitude: ${target.latitude}, '
      'longitude: ${target.longitude}, '
      'zoom_level: $zoom',
    );

    await controller.animateCamera(CameraUpdate.newLatLngZoom(target, zoom));
  }

  void _onCameraMove(CameraPosition position) async {
    final newZoom = position.zoom;
    final shouldShowMarkers = newZoom > 19;

    // Only update if the visibility state changes
    if (shouldShowMarkers != _shouldShowMarkers) {
      _currentZoom = newZoom;
      _shouldShowMarkers = shouldShowMarkers;

      // Update markers based on new zoom level
      final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
      await _updateMarkers(mapViewModel.locations);

      Sentry.logger.debug(
        'Marker visibility changed',
        attributes: {
          'zoom': SentryLogAttribute.string(newZoom.toString()),
          'visible': SentryLogAttribute.string(shouldShowMarkers.toString()),
        },
      );
    }
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    mapViewModel.removeListener(_onMapViewModelChanged);

    final combainInitializer = Provider.of<CombainIntializer>(
      context,
      listen: false,
    );
    combainInitializer.removeListener(_onSDKStateChanged);

    super.dispose();
  }
}
