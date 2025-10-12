import 'package:arkad/features/map/domain/entities/map_location.dart';
import 'package:arkad/features/map/presentation/view_models/map_view_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Widget for selecting floors within a building
///
/// Displays a horizontal list of floor labels and allows the user to select
/// a floor. The selected floor is managed by [MapViewModel].
class FloorSelectorWidget extends StatelessWidget {
  const FloorSelectorWidget({super.key, required this.building});

  /// The building ID to track floor selection for
  final MapBuilding building;

  @override
  Widget build(BuildContext context) {
    return Consumer<MapViewModel>(
      builder: (context, mapViewModel, child) {
        // Get the currently selected floor for this building
        final selectedFloorIndex =
            mapViewModel.buildingIdToFloorIndex[building.id] ??
            building.defaultFloorIndex;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1F2E),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: building.floors.map((floor) {
              final isSelected = floor.index == selectedFloorIndex;
              return GestureDetector(
                onTap: () {
                  // Update the floor selection in the view model
                  mapViewModel.updateBuildingFloor(building.id, floor.index);
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
                    floor.name,
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
