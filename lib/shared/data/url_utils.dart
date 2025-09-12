/// Utility class for handling URL construction and conversion
class UrlUtils {
  /// Base URL for the staging backend
  static const String baseUrl = 'https://staging.backend.arkadtlth.se';

  /// Convert relative path to full URL
  static String? buildFullUrl(String? relativePath) {
    if (relativePath == null || relativePath.isEmpty) return null;
    
    // Remove leading slash if present
    final cleanPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    
    // Handle different path patterns from the API
    if (cleanPath.startsWith('user/profile-picture/') || cleanPath.startsWith('user/cv/')) {
      // Convert API paths to media paths
      // user/profile-picture/... -> media/user/profile-pictures/...
      // user/cv/... -> media/user/cv/...
      final mediaPath = cleanPath.replaceFirst('user/profile-picture/', 'media/user/profile-pictures/')
                                 .replaceFirst('user/cv/', 'media/user/cv/');
      return '$baseUrl/$mediaPath';
    }
    
    // If already a full URL, return as-is
    if (relativePath.startsWith('http')) {
      return relativePath;
    }
    
    // Default: assume it's a media path
    return '$baseUrl/$cleanPath';
  }
}