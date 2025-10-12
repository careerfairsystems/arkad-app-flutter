import 'dart:io';

import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/entities/permission_request.dart';

class PermissionService {
  /// Check current permission status without requesting
  Future<PermissionStatus> checkPermissionStatus(PermissionType type) async {
    switch (type) {
      case PermissionType.location:
        final permission = Platform.isIOS
            ? ph.Permission.locationWhenInUse
            : ph.Permission.location;
        final status = await permission.status;
        return _mapStatus(status);

      case PermissionType.bluetoothScan:
        if (Platform.isAndroid) {
          final status = await ph.Permission.bluetoothScan.status;
          return _mapStatus(status);
        }
        return PermissionStatus
            .granted; // iOS doesn't need explicit Bluetooth scan permission
    }
  }

  Future<PermissionStatus> requestPermission(PermissionType type) async {
    switch (type) {
      case PermissionType.location:
        final permission = Platform.isIOS
            ? ph.Permission.locationWhenInUse
            : ph.Permission.location;
        final status = await permission.request();
        print("Requested location permission: $status");
        return _mapStatus(status);

      case PermissionType.bluetoothScan:
        if (Platform.isAndroid) {
          final status = await ph.Permission.bluetoothScan.request();
          return _mapStatus(status);
        }
        final status = await ph.Permission.bluetooth.request();
        return _mapStatus(status);
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
