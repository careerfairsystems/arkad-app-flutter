import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
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
  const MapScreen({super.key, this.selectedCompanyId});

  final int? selectedCompanyId;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Company? _selectedCompany;
  Set<Marker> _markers = {};
  Set<GroundOverlay> _groundOverlays = {};

  // Lund University coordinates (center of map)
  static const LatLng _lundCenter = LatLng(55.7104, 13.2109);

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

      // Load locations and buildings
      final imageConfig = createLocalImageConfiguration(context);
      mapViewModel.loadLocations().then((_) async {
        // Update ground overlays after buildings are loaded
        await _updateGroundOverlays(imageConfig, mapViewModel.buildings);
      });

      // Load companies if not already loaded (for company info cards)
      if (!companyViewModel.isInitialized) {
        companyViewModel.loadCompanies();
      }

      // Select and center on company if companyId is provided
      if (widget.selectedCompanyId != null) {
        final company = companyViewModel.getCompanyById(
          widget.selectedCompanyId!,
        );
        if (company != null) {
          setState(() {
            _selectedCompany = company;
          });
          _centerOnCompany(company);
        }
      }
    });
  }

  void _onLocationsChanged() async {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    final imageConfig = createLocalImageConfiguration(context);
    _updateMarkers(mapViewModel.locations);
    await _updateGroundOverlays(imageConfig, mapViewModel.buildings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ArkadColors.arkadNavy,
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
    return Stack(
      children: [
        // Map
        ArkadMapWidget(
          initialCameraPosition: const CameraPosition(
            target: _lundCenter,
            zoom: 15.0,
          ),
          markers: _markers,
          groundOverlays: _groundOverlays,
          onMapCreated: (controller) {
            _mapController = controller;
          },
          onTap: (_) {
            // Deselect company when tapping map
            if (_selectedCompany != null) {
              setState(() {
                _selectedCompany = null;
              });
            }
          },
        ),

        // Search bar at top
        Positioned(
          top: MediaQuery.of(context).padding.top + 16,
          left: 16,
          right: 16,
          child: MapSearchBar(
            onTap: _showSearchView,
            displayText: _selectedCompany?.name,
          ),
        ),

        // Selected company info card at bottom
        if (_selectedCompany != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: CompanyInfoCard(
              company: _selectedCompany!,
              onClose: () {
                setState(() {
                  _selectedCompany = null;
                });
              },
            ),
          ),
      ],
    );
  }

  Widget _buildPermissionFlow(MapPermissionsViewModel viewModel) {
    if (viewModel.currentStep == null) {
      return const Center(
        child: CircularProgressIndicator(color: ArkadColors.arkadTurkos),
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

  Future<void> _updateGroundOverlays(
    ImageConfiguration imageConfig,
    List<MapBuilding> buildings,
  ) async {
    final newOverlays = <GroundOverlay>{};

    for (final building in buildings) {
      // Use the default floor for each building
      final defaultFloor = building.floors.firstWhere(
        (floor) => floor.index == building.defaultFloorIndex,
        orElse: () => building.floors.first,
      );

      final floorMap = defaultFloor.map;

      // Create MapBitmap from AssetImage with proper configuration
      final mapBitmap = await AssetMapBitmap.create(
        imageConfig,
        (floorMap.image as AssetImage).assetName,
        bitmapScaling: MapBitmapScaling.none,
      );

      newOverlays.add(
        GroundOverlay.fromBounds(
          groundOverlayId: GroundOverlayId(
            'building_${building.id}_floor_${defaultFloor.index}',
          ),
          image: mapBitmap,
          bounds: LatLngBounds(
            southwest: LatLng(floorMap.SW.lat, floorMap.SW.lon),
            northeast: LatLng(floorMap.NE.lat, floorMap.NE.lon),
          ),
          transparency: 0.2,
        ),
      );
    }

    if (mounted) {
      setState(() {
        _groundOverlays = newOverlays;
      });
    }
  }

  void _updateMarkers(List<MapLocation> locations) {
    final newMarkers = <Marker>{};
    final companyViewModel = Provider.of<CompanyViewModel>(
      context,
      listen: false,
    );

    for (final location in locations) {
      // Get company for this location if it has a companyId
      Company? company;
      if (location.companyId != null) {
        company = companyViewModel.getCompanyById(location.companyId!);
      }

      final position = LatLng(location.latitude, location.longitude);
      final isSelected = company != null && _selectedCompany?.id == company.id;

      newMarkers.add(
        Marker(
          markerId: MarkerId(location.id.toString()),
          position: position,
          onTap: () {
            if (company != null) {
              setState(() {
                _selectedCompany = company;
              });
              _centerOnLocation(location);
            }
          },
          icon: isSelected
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                )
              : location.type == LocationType.booth
              ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan)
              : BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
          infoWindow: InfoWindow(
            title: location.name,
            snippet: location.type.displayName,
          ),
        ),
      );
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
          CameraPosition(target: position, zoom: 16.0),
        ),
      );
    }
  }

  void _centerOnCompany(Company company) {
    // Find the location for this company
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    final location = mapViewModel.locations.firstWhere(
      (loc) => loc.companyId == company.id,
      orElse: () => mapViewModel.locations.first,
    );

    _centerOnLocation(location);
  }

  void _showSearchView() {
    context.push(
      '/map/search',
      extra: (Company company) {
        setState(() {
          _selectedCompany = company;
        });
        _centerOnCompany(company);

        // Navigate back and update URL to reflect selected company
        context.go('/map/${company.id}');
      },
    );
  }

  @override
  void dispose() {
    final mapViewModel = Provider.of<MapViewModel>(context, listen: false);
    mapViewModel.removeListener(_onLocationsChanged);
    _mapController?.dispose();
    super.dispose();
  }
}
