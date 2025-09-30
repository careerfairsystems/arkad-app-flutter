import 'package:arkad/features/map/domain/entities/map_building.dart';

import '../../../../shared/domain/result.dart';
import '../entities/map_location.dart';

/// Repository interface for map operations
abstract class MapRepository {
  List<MapBuilding> getAllBuildings();
  
}
