import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;

import 'server_time_service.dart';

/// Central timezone service for handling Europe/Stockholm timezone operations
/// Provides consistent timezone conversion and formatting across the app
/// Uses the timezone package for accurate DST handling
/// Uses NTP time from ServerTimeService to prevent device time manipulation
class TimezoneService {
  const TimezoneService._();

  /// Stockholm timezone identifier
  static const String stockholmTimezone = 'Europe/Stockholm';

  /// Private instance for consistent access
  static const TimezoneService instance = TimezoneService._();

  /// Get current time in Stockholm timezone using NTP servers
  /// Use this instead of DateTime.now() for all timeline validations
  /// This prevents users from bypassing validation by changing device time
  /// Uses cached NTP offset for fast, synchronous access
  static DateTime stockholmNow() {
    final accurateUtcTime = ServerTimeService.instance.getAccurateNow();
    final stockholm = tz.getLocation(stockholmTimezone);
    return tz.TZDateTime.from(accurateUtcTime.toUtc(), stockholm);
  }

  /// Convert UTC DateTime to Stockholm timezone
  /// Use this for all API responses that come in UTC format
  static DateTime utcToStockholm(DateTime utcDateTime) {
    if (!utcDateTime.isUtc) {
      throw ArgumentError('DateTime must be in UTC format');
    }

    final stockholm = tz.getLocation(stockholmTimezone);
    final utcTzDateTime = tz.TZDateTime.from(utcDateTime, tz.UTC);
    return tz.TZDateTime.from(utcTzDateTime, stockholm);
  }

  /// Convert Stockholm DateTime back to UTC
  /// Use this when sending times to the backend API
  static DateTime stockholmToUtc(DateTime stockholmDateTime) {
    final stockholm = tz.getLocation(stockholmTimezone);
    final stockholmTzDateTime = tz.TZDateTime.from(
      stockholmDateTime,
      stockholm,
    );
    return stockholmTzDateTime.toUtc();
  }

  /// Format DateTime as date and time in Stockholm timezone
  /// Returns format: "5/10/2025 at 14:30"
  static String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('M/d/y \'at\' HH:mm', 'en_US');
    return formatter.format(_ensureStockholmTime(dateTime));
  }

  /// Format DateTime as time only in Stockholm timezone
  /// Returns format: "14:30"
  static String formatTime(DateTime dateTime) {
    final formatter = DateFormat('HH:mm', 'en_US');
    return formatter.format(_ensureStockholmTime(dateTime));
  }

  /// Format DateTime as date only in Stockholm timezone
  /// Returns format: "5 Oct"
  static String formatDate(DateTime dateTime) {
    final stockholmTime = _ensureStockholmTime(dateTime);
    final day = stockholmTime.day;
    final month = DateFormat('MMM', 'en_US').format(stockholmTime);
    return '$day $month';
  }

  /// Format DateTime with full locale-aware formatting
  /// Returns format: "Tuesday, October 5, 2025 at 2:30 PM"
  static String formatFullDateTime(DateTime dateTime) {
    final formatter = DateFormat('EEEE, MMMM d, y \'at\' h:mm a', 'en_US');
    return formatter.format(_ensureStockholmTime(dateTime));
  }

  /// Format DateTime for company events
  /// Returns format: "Oct 05, 2025 at 14:30"
  static String formatEventDateTime(DateTime dateTime) {
    final formatter = DateFormat('MMM dd, y \'at\' HH:mm', 'en_US');
    return formatter.format(_ensureStockholmTime(dateTime));
  }

  /// Check if a DateTime is in the past relative to Stockholm time
  static bool isInPast(DateTime dateTime, {DateTime? relativeTo}) {
    final stockholmTime = _ensureStockholmTime(dateTime);
    final compareTime = relativeTo ?? stockholmNow();
    return stockholmTime.isBefore(compareTime);
  }

  /// Check if a DateTime is in the future relative to Stockholm time
  static bool isInFuture(DateTime dateTime, {DateTime? relativeTo}) {
    final stockholmTime = _ensureStockholmTime(dateTime);
    final compareTime = relativeTo ?? stockholmNow();
    return stockholmTime.isAfter(compareTime);
  }

  /// Get time difference from now in Stockholm timezone
  static Duration differenceFromNow(DateTime dateTime) {
    final stockholmTime = _ensureStockholmTime(dateTime);
    final now = stockholmNow();
    return stockholmTime.difference(now);
  }

  // Private helper methods

  /// Ensure DateTime is treated as Stockholm time
  /// If it's UTC, convert it. If it's local/unknown, treat as Stockholm.
  static DateTime _ensureStockholmTime(DateTime dateTime) {
    if (dateTime.isUtc) {
      return utcToStockholm(dateTime);
    }
    final stockholm = tz.getLocation(stockholmTimezone);
    return tz.TZDateTime.from(dateTime, stockholm);
  }
}
