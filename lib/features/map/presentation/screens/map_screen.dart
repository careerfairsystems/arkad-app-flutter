import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/view_models/company_view_model.dart';
import '../view_models/map_permissions_view_model.dart';
import '../widgets/arkad_map_widget.dart';
import '../widgets/company_info_card.dart';
import '../widgets/company_search_sheet.dart';
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

  // Lund University coordinates (center of map)
  static const LatLng _lundCenter = LatLng(55.7104, 13.2109);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final companyViewModel = Provider.of<CompanyViewModel>(
        context,
        listen: false,
      );

      // Load companies if not already loaded
      if (!companyViewModel.isInitialized) {
        companyViewModel.loadCompanies();
      }

      // Build markers
      _updateMarkers(companyViewModel.allCompanies);

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
        Consumer<CompanyViewModel>(
          builder: (context, companyViewModel, child) {
            // Update markers when companies change
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateMarkers(companyViewModel.allCompanies);
            });

            return ArkadMapWidget(
              initialCameraPosition: const CameraPosition(
                target: _lundCenter,
                zoom: 15.0,
              ),
              markers: _markers,
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
            );
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

  void _updateMarkers(List<Company> companies) {
    final newMarkers = <Marker>{};

    for (int i = 0; i < companies.length; i++) {
      final company = companies[i];
      final location = _getMockLocation(i, companies.length);

      newMarkers.add(
        Marker(
          markerId: MarkerId(company.id.toString()),
          position: location,
          onTap: () {
            setState(() {
              _selectedCompany = company;
            });
            _centerOnCompany(company);
          },
          icon: _selectedCompany?.id == company.id
              ? BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                )
              : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          infoWindow: InfoWindow(
            title: company.name,
            snippet: company.industries.isNotEmpty
                ? company.industries.first
                : null,
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

  /// Generate mock locations in a grid pattern around Lund center
  LatLng _getMockLocation(int index, int total) {
    // Create a grid pattern
    const double gridSize = 0.004; // ~400m spacing
    const int cols = 5;

    final row = index ~/ cols;
    final col = index % cols;

    // Offset from center
    final latOffset = (row - 2) * gridSize;
    final lngOffset = (col - 2) * gridSize;

    return LatLng(
      _lundCenter.latitude + latOffset,
      _lundCenter.longitude + lngOffset,
    );
  }

  void _centerOnCompany(Company company) {
    // Find the company index to get its location
    final companyViewModel = Provider.of<CompanyViewModel>(
      context,
      listen: false,
    );
    final companies = companyViewModel.allCompanies;
    final index = companies.indexWhere((c) => c.id == company.id);

    if (index != -1 && _mapController != null) {
      final location = _getMockLocation(index, companies.length);
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 16.0),
        ),
      );
    }
  }

  void _showSearchView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CompanySearchSheet(
        onCompanySelected: (company) {
          setState(() {
            _selectedCompany = company;
          });
          _centerOnCompany(company);
          Navigator.pop(context);

          // Update URL to reflect selected company
          context.go('/map/${company.id}');
        },
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
