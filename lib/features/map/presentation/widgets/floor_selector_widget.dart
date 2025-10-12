import 'package:arkad/features/map/presentation/view_models/map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget for selecting floors within a building
///
/// Displays a horizontal list of floor labels and allows the user to select
/// a floor. The selected floor is managed by [MapViewModel].
class FloorSelectorWidget extends StatelessWidget {
  const FloorSelectorWidget({
    super.key,
    required this.availableFloors,
    required this.buildingId,
  });

  /// List of available floors as (floorIndex, floorLabel) tuples
  final List<(int floorIndex, String floorLabel)> availableFloors;

  /// The building ID to track floor selection for
  final int buildingId;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        // Get the currently selected floor for this building
        final selectedFloorIndex =
            mapViewModel.buildingIdToFloorIndex[buildingId] ??
            availableFloors.firstOrNull?.$1 ??
            0;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: availableFloors.map((floor) {
              final isSelected = floor.$1 == selectedFloorIndex;
              return GestureDetector(
                onTap: () {
                  // Update the floor selection in the view model
                  mapViewModel.updateBuildingFloor(buildingId, floor.$1);
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
      },
    );
  }
}
