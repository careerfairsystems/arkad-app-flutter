/// Utility class for handling URL construction and conversion
class UrlUtils {
  /// Base URL for the staging backend
  static const String baseUrl = 'https://staging.backend.arkadtlth.se';

  /// Convert relative path to full URL
  /// Backend returns relative paths like '/user/profile-picture/...' or '/user/cv/...'
  /// These need to be converted to full media URLs
  static String? buildFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;

    // Remove leading slash if present
    final cleanPath =
        relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;

    // Convert API paths to media paths
    if (cleanPath.startsWith('user/profile-picture/') ||
        cleanPath.startsWith('user/cv/')) {
      // user/profile-picture/... -> media/user/profile-picture/...
      // user/cv/... -> media/user/cv/...
      final mediaPath = cleanPath
          .replaceFirst('user/profile-picture/', 'media/user/profile-picture/')
          .replaceFirst('user/cv/', 'media/user/cv/');
      return '$baseUrl/$mediaPath';
    }

    // Default case for other relative paths
    return '$baseUrl/$cleanPath';
  }
}
