import 'package:sentry_flutter/sentry_flutter.dart';

class SentryUtils {
  static void captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Hint? reason,
  }) {
    Sentry.captureException(exception, stackTrace: stackTrace, hint: reason);
  }
}
