import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../company/domain/entities/company.dart';
import '../../../company/presentation/view_models/company_view_model.dart';
import '../view_models/map_permissions_view_model.dart';
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
              return Stack(
                children: [
                  // Map
                  Consumer<CompanyViewModel>(
                    builder: (context, companyViewModel, child) {
                      // Update markers when companies change
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateMarkers(companyViewModel.allCompanies);
                      });

                      return GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          _setMapStyle(controller);
                        },
                        initialCameraPosition: const CameraPosition(
                          target: _lundCenter,
                          zoom: 15.0,
                        ),
                        markers: _markers,
                        minMaxZoomPreference: const MinMaxZoomPreference(
                          12.0,
                          18.0,
                        ),
                        onTap: (_) {
                          // Deselect company when tapping map
                          if (_selectedCompany != null) {
                            setState(() {
                              _selectedCompany = null;
                            });
                          }
                        },
                        myLocationEnabled: true,
                      );
                    },
                  ),

                  // Search bar at top
                  Positioned(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16,
                    child: _buildSearchBar(),
                  ),

                  // Selected company info card at bottom
                  if (_selectedCompany != null)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: _buildCompanyInfoCard(_selectedCompany!),
                    ),
                ],
              );
            },
          );
        },
      ),
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

  Widget _buildSearchBar() {
    return GestureDetector(
      onTap: () {
        // Open search view
        _showSearchView();
      },
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: ArkadColors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ArkadColors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 20),
            const Icon(Icons.search, color: ArkadColors.arkadNavy, size: 24),
            const SizedBox(width: 16),
            Text(
              _selectedCompany != null
                  ? _selectedCompany!.name
                  : 'Search companies',
              style: TextStyle(
                color: _selectedCompany != null
                    ? ArkadColors.arkadNavy
                    : ArkadColors.gray,
                fontSize: 16,
                fontFamily: 'MyriadProCondensed',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyInfoCard(Company company) {
    return Card(
      color: ArkadColors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Company logo or placeholder
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ArkadColors.arkadLightNavy,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: company.logoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            company.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.business,
                              color: ArkadColors.arkadTurkos,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.business,
                          color: ArkadColors.arkadTurkos,
                        ),
                ),
                const SizedBox(width: 16),

                // Company name and industry
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        company.name,
                        style: const TextStyle(
                          color: ArkadColors.arkadNavy,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'MyriadProCondensed',
                        ),
                      ),
                      if (company.industries.isNotEmpty)
                        Text(
                          company.industries.first,
                          style: const TextStyle(
                            color: ArkadColors.gray,
                            fontSize: 14,
                            fontFamily: 'MyriadProCondensed',
                          ),
                        ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close),
                  color: ArkadColors.arkadNavy,
                  onPressed: () {
                    setState(() {
                      _selectedCompany = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // View details button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/companies/detail/${company.id}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArkadColors.arkadTurkos,
                  foregroundColor: ArkadColors.white,
                ),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
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

  Future<void> _setMapStyle(GoogleMapController controller) async {
    try {
      final String style = await rootBundle.loadString(
        'assets/map_styles/arkad_dark_map_style.json',
      );
      await controller.setMapStyle(style);
    } catch (e) {
      // Map style loading failed, continue with default style
      debugPrint('Failed to load map style: $e');
    }
  }

  void _showSearchView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CompanySearchView(
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

/// Search view for filtering companies
class _CompanySearchView extends StatefulWidget {
  const _CompanySearchView({required this.onCompanySelected});

  final void Function(Company) onCompanySelected;

  @override
  State<_CompanySearchView> createState() => _CompanySearchViewState();
}

class _CompanySearchViewState extends State<_CompanySearchView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: ArkadColors.arkadNavy,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ArkadColors.lightGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Search field
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(
                    color: ArkadColors.white,
                    fontFamily: 'MyriadProCondensed',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search companies',
                    hintStyle: const TextStyle(
                      color: ArkadColors.lightGray,
                      fontFamily: 'MyriadProCondensed',
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: ArkadColors.arkadTurkos,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: ArkadColors.arkadTurkos,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: ArkadColors.arkadLightNavy,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              // Company list
              Expanded(
                child: Consumer<CompanyViewModel>(
                  builder: (context, companyViewModel, child) {
                    final companies = companyViewModel.allCompanies
                        .where(
                          (company) => company.matchesSearchQuery(_searchQuery),
                        )
                        .toList();

                    if (companyViewModel.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: ArkadColors.arkadTurkos,
                        ),
                      );
                    }

                    if (companies.isEmpty) {
                      return Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No companies available'
                              : 'No companies found',
                          style: const TextStyle(
                            color: ArkadColors.lightGray,
                            fontFamily: 'MyriadProCondensed',
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: companies.length,
                      itemBuilder: (context, index) {
                        final company = companies[index];
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ArkadColors.arkadLightNavy,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: company.logoUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      company.logoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(
                                        Icons.business,
                                        color: ArkadColors.arkadTurkos,
                                      ),
                                    ),
                                  )
                                : const Icon(
                                    Icons.business,
                                    color: ArkadColors.arkadTurkos,
                                  ),
                          ),
                          title: Text(
                            company.name,
                            style: const TextStyle(
                              color: ArkadColors.white,
                              fontFamily: 'MyriadProCondensed',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: company.industries.isNotEmpty
                              ? Text(
                                  company.industries.first,
                                  style: const TextStyle(
                                    color: ArkadColors.lightGray,
                                    fontFamily: 'MyriadProCondensed',
                                  ),
                                )
                              : null,
                          onTap: () {
                            widget.onCompanySelected(company);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
