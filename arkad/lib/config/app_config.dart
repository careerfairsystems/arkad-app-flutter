/// Configuration class for app-wide settings
class AppConfig {
  // Environment-specific URLs
  static const String _devBaseUrl = 'https://dev.backend.arkadtlth.se/api';
  static const String _stagingBaseUrl =
      'https://staging.backend.arkadtlth.se/api';
  static const String _prodBaseUrl = 'https://backend.arkadtlth.se/api';

  // Current environment - can be changed to 'dev', 'staging', or 'prod'
  static const String _environment = 'staging';

  /// Base URL for the API, determined by current environment
  static String get baseUrl {
    switch (_environment) {
      case 'dev':
        return _devBaseUrl;
      case 'staging':
        return _stagingBaseUrl;
      case 'prod':
        return _prodBaseUrl;
      default:
        return _stagingBaseUrl;
    }
  }
}
