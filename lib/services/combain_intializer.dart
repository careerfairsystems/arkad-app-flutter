import 'dart:async';
import 'package:arkad/navigation/navigation_items.dart';
import 'package:arkad/services/env.dart';
import 'package:arkad/services/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_combainsdk/flutter_combain_sdk.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:get_it/get_it.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum CombainInitializationState {
  failed,
  uninitialized,
  initializing,
  initialized,
  starting,
  started;

  bool mapReady() {
    return index >= CombainInitializationState.initialized.index;
  }
}

class CombainIntializer extends ChangeNotifier {
  final PackageInfo _packageInfo;

  CombainIntializer(this._packageInfo);

  var state = CombainInitializationState.uninitialized;
  String? _errorInfo;

  FlutterCombainSDK? _combainSDK;

  String? get errorInfo => _errorInfo;

  /// Mark as initialized (used for web platform)

  Future<void> registerSDK() async {
    if (_combainSDK != null) {
      print("Combain SDK already initialized");
      return;
    }

    print("Running combain SDK configuration");

    // Step 1: Create the SDK instance with logging and exception capture
    _combainSDK = await FlutterCombainSDK.create(
      constructorConfig: ConstructorConfig(
        debug: false,
        logger: ArkadCombainLogger(),
        exceptionCapture: ArkadCombainExceptionCapture(),
        alsoNativeLogs: kDebugMode, // Enable native logs in debug mode
      ),
    );

    // Register SDK instance so it can be used by PermissionsDataSource
    serviceLocator.registerSingleton(_combainSDK!);
  }

  /// Initialize SDK without starting it (config setup only)
  Future<void> initializeWithoutStart() async {
    if (!shouldShowMap()) {
      return;
    }

    // Early null check for SDK instance
    if (_combainSDK == null) {
      state = CombainInitializationState.failed;
      _errorInfo = 'SDK instance not registered. Call registerSDK() first.';
      notifyListeners();
      print("Cannot initialize SDK - not registered: $_errorInfo");
      return;
    }

    // Set state to initializing before starting
    state = CombainInitializationState.initializing;
    _errorInfo = null;
    notifyListeners();
    print("Initializing SDK config");

    try {
      // Step 2: Initialize the SDK with the config
      // Combain SDK initialization with persistent device UUID
      final deviceId = await getOrCreateDeviceId();
      final env = GetIt.I<Env>();

      final combainConfig = CombainSDKConfig(
        apiKey: env.combainApiKey,
        settingsKey: env.combainApiKey,

        locationProvider: FlutterLocationProvider.aiNavigation,
        routingConfig: FlutterRoutingConfig(
          routableNodesOptions: FlutterRoutableNodesOptions.allExceptDefaultName,
        ),
        appInfo: FlutterAppInfo(
          packageName: _packageInfo.packageName,
          versionName: _packageInfo.version,
          versionCode: int.tryParse(_packageInfo.buildNumber) ?? 0,
        ),
        syncingInterval: FlutterSyncingInterval(
          type: FlutterSyncingIntervalType.onStart,
          intervalMilliseconds: 60 * 1000 * 60,
        ),
        wifiEnabled: true,
        bluetoothEnabled: true,
        beaconUUIDs: ["E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"],
      );
      await _combainSDK!.initializeSDK(combainConfig);

      // Success - update state
      state = CombainInitializationState.initialized;
      notifyListeners();
      print("Initialized SDK config successfully");
    } catch (e, stackTrace) {
      // Failure - capture error and update state
      state = CombainInitializationState.failed;
      _errorInfo = 'SDK initialization failed: $e';
      notifyListeners();
      print("Failed to initialize SDK: $e\n$stackTrace");
      rethrow;
    }
  }

  /// Start the SDK after permissions are granted
  Future<void> startSDK() async {
    if (!shouldShowMap()) {
      return;
    }
    if (_combainSDK == null) {
      print("Cannot start SDK - not initialized");
      return;
    }

    if (state != CombainInitializationState.initialized) {
      print("Cannot start SDK - not in initialized state it is in $state");
      return;
    }

    print("Starting Combain SDK");
    await _combainSDK!.start();
    state = CombainInitializationState.started;
    print("Combain SDK started successfully");
    notifyListeners();
  }
}
