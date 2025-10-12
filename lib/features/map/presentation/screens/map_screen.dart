import 'package:arkad/services/service_locator.dart';
import 'package:flutter/material.dart';
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
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  MapLocation? _pendingZoomLocation;
  MapBuilding? currentFocusedBuilding;
  double _currentZoom = 18.0;
  bool _shouldShowMarkers = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
      final companyViewModel = Provider.of<CompanyViewModel>(
        context,
        listen: false,
      );

      // Listen to map location changes and update markers
      mapViewModel.addListener(_onLocationsChanged);

      // Load locations, buildings, and ground overlays
      final imageConfig = createLocalImageConfiguration(context);
      mapViewModel.loadLocations().then((_) async {
        // Load ground overlays after buildings are loaded
        await mapViewModel.loadGroundOverlays(imageConfig);
        await _updateMarkers(mapViewModel.locations);
      });

      // Load companies if not already loaded (for company info cards)
      if (!companyViewModel.isInitialized) {
        companyViewModel.loadCompanies();
      }
    });
  }

  void _onLocationsChanged() async {
    // React to MapViewModel changes (company selection from search, etc.)
    if (!mounted) return;

    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);

    // Update markers when locations change
    await _updateMarkers(mapViewModel.locations);

    // When a company is selected, zoom to its location
    if (mapViewModel.selectedLocation != null) {
      final location = mapViewModel.selectedLocation!;

      // Validate location has valid coordinates before zooming
      if (location.latitude != 0 && location.longitude != 0) {
        if (_mapController != null) {
          _centerOnLocation(location);
          _pendingZoomLocation = null;

          Sentry.logger.info(
            'Zoomed to company location',
            attributes: {
              'company_id': SentryLogAttribute.string(
                mapViewModel.selectedCompanyId!.toString(),
              ),
              'latitude': SentryLogAttribute.string(
                location.latitude.toString(),
              ),
              'longitude': SentryLogAttribute.string(
                location.longitude.toString(),
              ),
            },
          );
        } else {
          // Map controller not ready yet, queue the zoom for when it's ready
          _pendingZoomLocation = location;
          debugPrint('Map controller not ready, queuing zoom for later');

          Sentry.logger.debug(
            'Map controller not ready, queuing zoom',
            attributes: {
              'company_id': SentryLogAttribute.string(
                mapViewModel.selectedCompanyId!.toString(),
              ),
            },
          );
        }
      } else {
        Sentry.logger.error(
          'Invalid location coordinates for company',
          attributes: {
            'company_id': SentryLogAttribute.string(
              mapViewModel.selectedCompanyId!.toString(),
            ),
            'latitude': SentryLogAttribute.string(location.latitude.toString()),
            'longitude': SentryLogAttribute.string(
              location.longitude.toString(),
            ),
          },
        );
      }
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
              if (!combainInitializer.combainIntialized ||
                  permissionsViewModel.isStartingSDK) {
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
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;

                // Process any pending zoom operation
                if (_pendingZoomLocation != null) {
                  debugPrint('Processing pending zoom after map creation');
                  _centerOnLocation(_pendingZoomLocation!);

                  Sentry.logger.info(
                    'Processed pending zoom after map creation',
                    attributes: {
                      'company_id': SentryLogAttribute.string(
                        mapViewModel.selectedCompanyId!.toString(),
                      ),
                    },
                  );

                  _pendingZoomLocation = null;
                }
              },
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
        _centerOnLocation(location);
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
    }

    if (mounted) {
      setState(() {
        _markers = newMarkers;
      });
    }
  }

  void _centerOnLocation(MapLocation location) {
    if (_mapController != null) {
      final position = LatLng(location.latitude, location.longitude);
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 22.0),
        ),
      );
    }
  }

  void _showSearchView() {
    context.push('/map/search');
  }

  void _onCameraMove(CameraPosition position) async {
    final newZoom = position.zoom;
    final shouldShowMarkers = newZoom > 20;

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
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    mapViewModel.removeListener(_onLocationsChanged);
    _mapController?.dispose();
    super.dispose();
  }
}
