import 'package:arkad/features/map/domain/repositories/location_repository.dart';
import 'package:arkad/features/map/presentation/providers/capture_payload.dart';
import 'package:arkad/services/env.dart';
import 'package:arkad/services/service_locator.dart';
import 'package:dio/dio.dart';
import 'package:flutter_combainsdk/messages.g.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Implementation of LocationRepository using LocationDataSource
class LocationRepositoryImpl implements LocationRepository {
  final Dio _dio = Dio();
  @override
  Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<bool> requestLocationPermission() async {
    final permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  @override
  Future<void> captureLocation(FlutterCombainLocation location) async {
    try {
      final env = GetIt.I<Env>();
      final serviceToken = env.combainServiceToken;
      final deviceId = await getOrCreateDeviceId();
      final url =
          "https://online.traxmate.io/api/capture/service/$serviceToken/device/$deviceId";
      final body = CapturePayload.fromCombainLocation(location);

      await _dio.post(
        url,
        data: body.toJson(),
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
    } catch (e, stackTrace) {
      await Sentry.captureException(
        e,
        stackTrace: stackTrace,
        hint: Hint.withMap({
          'context': 'Failed to capture location to TraxMate API',
          'url': 'https://online.traxmate.io/api/capture/...',
        }),
      );
    }
  }
}
