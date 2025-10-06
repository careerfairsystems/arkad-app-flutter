import 'package:flutter/foundation.dart';

/// Simple environment configuration for backend URL switching
class AppEnvironment {
  /// Use staging in debug mode, production in release mode
  static bool get isStaging => kDebugMode;

  /// Get the appropriate backend base URL
  static String get baseUrl {
    return isStaging
        ? 'https://staging.backend.arkadtlth.se'
        : 'https://backend.arkadtlth.se';
  }

  /// Get the appropriate OpenAPI spec URL
  static String get openApiUrl => '$baseUrl/api/openapi.json';

  /// Current environment name for logging/debugging
  static String get environmentName => isStaging ? 'staging' : 'production';
}
