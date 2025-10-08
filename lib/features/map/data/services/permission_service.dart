import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/entities/permission_request.dart';

class PermissionService {
  Future<PermissionStatus> requestPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.location:
        final permission = Platform.isIOS
            ? ph.Permission.locationWhenInUse
            : ph.Permission.location;
        final status = await permission.request();
        return _mapStatus(status);

      case PermissionType.bluetoothScan:
        if (Platform.isAndroid) {
          final status = await ph.Permission.bluetoothScan.request();
          return _mapStatus(status);
        }
        return PermissionStatus
            .granted; // iOS doesn't need explicit Bluetooth scan permission
    }
  }

  PermissionStatus _mapStatus(ph.PermissionStatus status) {
    switch (status) {
      case ph.PermissionStatus.granted:
      case ph.PermissionStatus.limited:
        return PermissionStatus.granted;
      case ph.PermissionStatus.denied:
        return PermissionStatus.denied;
      case ph.PermissionStatus.permanentlyDenied:
        return PermissionStatus.permanentlyDenied;
      case ph.PermissionStatus.restricted:
      case ph.PermissionStatus.provisional:
        return PermissionStatus.denied;
    }
  }
}
