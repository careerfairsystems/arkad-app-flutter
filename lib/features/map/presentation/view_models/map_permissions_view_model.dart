import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../../../services/combain_intializer.dart';
import '../../data/services/permission_service.dart';
import '../../domain/entities/permission_request.dart';

/// Manages permission flow specifically for map features
class MapPermissionsViewModel extends ChangeNotifier {
  MapPermissionsViewModel({
    required PermissionService permissionService,
    required CombainIntializer combainInitializer,
  }) : _permissionService = permissionService,
       _combainInitializer = combainInitializer {
    _initializeSteps();
  }

  final PermissionService _permissionService;
  final CombainIntializer _combainInitializer;

  List<PermissionRequest> _steps = [];
  List<PermissionRequest> get steps => _steps;

  int _currentStepIndex = 0;
  int get currentStepIndex => _currentStepIndex;

  PermissionRequest? get currentStep =>
      _currentStepIndex < _steps.length ? _steps[_currentStepIndex] : null;

  bool get hasMoreSteps => _currentStepIndex < _steps.length - 1;
  bool get isFirstStep => _currentStepIndex == 0;
  bool get isLastStep => _currentStepIndex == _steps.length - 1;

  bool _allPermissionsGranted = false;
  bool get allPermissionsGranted => _allPermissionsGranted;

  bool _isStartingSDK = false;
  bool get isStartingSDK => _isStartingSDK;

  bool _isRequestingPermission = false;
  bool get isRequestingPermission => _isRequestingPermission;

  bool _isCheckingPermissions = true;
  bool get isCheckingPermissions => _isCheckingPermissions;

  void _initializeSteps() {
    _steps = [
      const PermissionRequest(
        type: PermissionType.location,
        title: 'Location Permission',
        description:
            'We need access to your location to show you on the map and provide navigation.',
        iconPath: 'assets/images/onboarding/motion.png',
        status: PermissionStatus.notRequested,
      ),
      if (Platform.isAndroid)
        const PermissionRequest(
          type: PermissionType.activityRecognition,
          title: 'Activity Recognition Permission',
          description:
              'We need activity recognition to detect your movement and improve indoor positioning accuracy.',
          iconPath: 'assets/images/onboarding/motion.png',
          status: PermissionStatus.notRequested,
        ),
      if (Platform.isAndroid)
        const PermissionRequest(
          type: PermissionType.bluetoothScan,
          title: 'Bluetooth Permission',
          description:
              'We need Bluetooth access for indoor positioning and navigation.',
          iconPath: 'assets/images/onboarding/motion.png',
          status: PermissionStatus.notRequested,
        ),
    ];

    // Check existing permissions after initialization
    _checkExistingPermissions();
  }

  /// Check if permissions are already granted on app start
  Future<void> _checkExistingPermissions() async {
    _isCheckingPermissions = true;
    notifyListeners();

    try {
      // Check each permission's current status
      for (int i = 0; i < _steps.length; i++) {
        final status = await _permissionService.checkPermissionStatus(
          _steps[i].type,
        );
        _steps[i] = _steps[i].copyWith(status: status);
      }

      // Check if all permissions are already granted
      await _checkAllPermissions();

      // If not all granted, find first non-granted permission
      if (!_allPermissionsGranted) {
        _currentStepIndex = _steps.indexWhere(
          (step) => step.status != PermissionStatus.granted,
        );
        if (_currentStepIndex == -1) {
          _currentStepIndex = 0;
        }
      }
    } catch (e) {
      debugPrint('Error checking existing permissions: $e');
    } finally {
      _isCheckingPermissions = false;
      notifyListeners();
    }
  }

  Future<void> requestCurrentPermission() async {
    if (currentStep == null || _isRequestingPermission) return;

    _isRequestingPermission = true;
    notifyListeners();

    try {
      final status = await _permissionService.requestPermission(
        currentStep!.type,
      );
      _updateStepStatus(currentStep!.type, status);

      // Automatically advance if permission was granted
      if (status == PermissionStatus.granted) {
        if (hasMoreSteps) {
          nextStep();
        } else {
          // All steps completed, check if all permissions granted
          await _checkAllPermissions();
        }
      }
    } catch (e) {
      debugPrint('Error requesting permission: $e');
    } finally {
      _isRequestingPermission = false;
      notifyListeners();
    }
  }

  void _updateStepStatus(PermissionType type, PermissionStatus status) {
    final index = _steps.indexWhere((step) => step.type == type);
    if (index != -1) {
      _steps[index] = _steps[index].copyWith(status: status);
    }
  }

  Future<void> _checkAllPermissions() async {
    final allGranted = _steps.every(
      (step) => step.status == PermissionStatus.granted,
    );

    if (allGranted && !_allPermissionsGranted) {
      _allPermissionsGranted = true;

      // Start Combain SDK now that permissions are granted
      _isStartingSDK = true;
      notifyListeners();

      try {
        await _combainInitializer.startSDK();
        debugPrint(
          'Combain SDK started successfully after permissions granted',
        );
      } catch (e) {
        debugPrint('Error starting Combain SDK: $e');
      } finally {
        _isStartingSDK = false;
        notifyListeners();
      }
    }
  }

  void nextStep() {
    if (hasMoreSteps) {
      _currentStepIndex++;
      notifyListeners();
    }
  }

  void previousStep() {
    if (!isFirstStep) {
      _currentStepIndex--;
      notifyListeners();
    }
  }

  Future<void> openSettings() async {
    // Open app settings so user can grant permissions
    // This is a placeholder - you can use app_settings package
  }
}
