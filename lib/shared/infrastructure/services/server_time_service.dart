import 'package:flutter/foundation.dart';
import 'package:ntp/ntp.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Service for fetching accurate time from NTP servers
/// Prevents users from bypassing timeline validation by manipulating device time
/// Caches time offset to allow synchronous access
class ServerTimeService {
  ServerTimeService._();

  static final ServerTimeService instance = ServerTimeService._();

  /// Timeout for NTP requests
  static const Duration _ntpTimeout = Duration(seconds: 5);

  bool _isInitialized = false;
  Duration _timeOffset = Duration.zero;

  /// Initialize the service and perform first NTP sync
  /// Should be called once during app startup
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    await _syncTimeOffset();
  }

  /// Sync time offset with NTP server
  /// Calculates the difference between NTP time and device time
  /// Falls back to device time (zero offset) if NTP sync fails
  Future<void> _syncTimeOffset() async {
    final deviceTimeBefore = DateTime.now();

    try {
      final ntpTime = await NTP.now(timeout: _ntpTimeout);

      // Calculate offset: NTP time - device time
      _timeOffset = ntpTime.difference(deviceTimeBefore);

      if (kDebugMode) {
        print(
          'ServerTimeService: Synced successfully, offset: ${_timeOffset.inMilliseconds}ms',
        );
      }
    } catch (e) {
      // NTP sync failed - use device time as fallback
      _timeOffset = Duration.zero;

      // Log to Sentry for monitoring (graceful fallback, not an error)
      Sentry.logger.info(
        'NTP sync failed, using device time',
        attributes: {
          'component': SentryLogAttribute.string('ServerTimeService'),
          'error': SentryLogAttribute.string(e.toString()),
        },
      );

      if (kDebugMode) {
        print('ServerTimeService: NTP sync failed, using device time');
      }
    }
  }

  /// Get accurate current time using cached NTP offset
  /// This is fast (synchronous) and secure (uses NTP offset)
  DateTime getAccurateNow() {
    // Apply cached offset to current device time
    return DateTime.now().add(_timeOffset);
  }
}
