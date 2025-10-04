/// Service for common validation operations
class ValidationService {
  /// Validate LinkedIn profile URL or username
  /// Accepts various formats:
  /// - Full URLs: https://www.linkedin.com/in/username, www.linkedin.com/in/username
  /// - Just usernames: john_doe
  static bool isValidLinkedInUrl(String url) {
    // Accept LinkedIn URLs in various formats and just usernames
    final patterns = [
      r'^https://www\.linkedin\.com/in/[a-zA-Z0-9_.-]+/?$', // https://www.linkedin.com/in/username
      r'^https://linkedin\.com/in/[a-zA-Z0-9_.-]+/?$', // https://linkedin.com/in/username
      r'^www\.linkedin\.com/in/[a-zA-Z0-9_.-]+/?$', // www.linkedin.com/in/username
      r'^linkedin\.com/in/[a-zA-Z0-9_.-]+/?$', // linkedin.com/in/username
      r'^[a-zA-Z0-9_.-]+$', // Just username (can include dots)
    ];

    return patterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url),
    );
  }

  /// Build a full LinkedIn URL from user input
  /// Converts usernames to full URLs, validates LinkedIn domains only
  /// Examples:
  /// - 'john-smith' → 'https://www.linkedin.com/in/john-smith'
  /// - 'www.linkedin.com/in/john' → 'https://www.linkedin.com/in/john'
  /// - 'https://linkedin.com/in/jane' → 'https://www.linkedin.com/in/jane'
  /// - 'https://evil.com' → 'https://www.linkedin.com/in/evil.com' (treated as username)
  static String buildLinkedInUrl(String input) {
    final trimmed = input.trim();

    // If already a URL, normalize and allow only LinkedIn hosts
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final https = trimmed.replaceFirst('http://', 'https://');
      final uri = Uri.tryParse(https);
      if (uri != null) {
        final host = uri.host.toLowerCase();
        if (host == 'www.linkedin.com' || host == 'linkedin.com') {
          return uri.replace(scheme: 'https').toString();
        }
      }
      // Not a LinkedIn host → treat as username
      final asUser = uri?.pathSegments.isNotEmpty == true
          ? uri!.pathSegments.last
          : https;
      return 'https://www.linkedin.com/in/${Uri.encodeComponent(asUser)}';
    }

    // If starts with www.linkedin.com or linkedin.com, add https://
    if (trimmed.startsWith('www.linkedin.com/in/') ||
        trimmed.startsWith('linkedin.com/in/')) {
      return 'https://$trimmed';
    }

    // If it's just a username, build full LinkedIn URL
    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(trimmed)) {
      return 'https://www.linkedin.com/in/$trimmed';
    }

    // Fallback: treat as username
    return 'https://www.linkedin.com/in/${Uri.encodeComponent(trimmed)}';
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  /// Must be at least 8 characters long
  static bool isValidPassword(String password) {
    return password.length >= 8;
  }

  /// Validate study year (1-5)
  static bool isValidStudyYear(int? studyYear) {
    if (studyYear == null) return true; // Optional field
    return studyYear >= 1 && studyYear <= 5;
  }

  /// Validate required string field (not empty)
  static bool isRequiredFieldValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
