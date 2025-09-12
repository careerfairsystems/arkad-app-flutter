/// Service for common validation operations
class ValidationService {
  /// Validate LinkedIn profile URL or username
  /// Accepts various formats:
  /// - Full URLs: https://www.linkedin.com/in/username, www.linkedin.com/in/username
  /// - Just usernames: john_doe
  static bool isValidLinkedInUrl(String url) {
    // Accept LinkedIn URLs in various formats and just usernames
    final patterns = [
      r'^https://www\.linkedin\.com/in/[a-zA-Z0-9_-]+/?$', // https://www.linkedin.com/in/username
      r'^https://linkedin\.com/in/[a-zA-Z0-9_-]+/?$', // https://linkedin.com/in/username
      r'^www\.linkedin\.com/in/[a-zA-Z0-9_-]+/?$', // www.linkedin.com/in/username
      r'^linkedin\.com/in/[a-zA-Z0-9_-]+/?$', // linkedin.com/in/username
      r'^[a-zA-Z0-9_-]+$', // Just username
    ];

    return patterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url),
    );
  }

  /// Build a full LinkedIn URL from user input
  /// Converts usernames to full URLs, returns full URLs unchanged
  /// Examples:
  /// - 'john-smith' → 'https://www.linkedin.com/in/john-smith'
  /// - 'www.linkedin.com/in/john' → 'https://www.linkedin.com/in/john'
  /// - 'https://linkedin.com/in/jane' → 'https://linkedin.com/in/jane'
  static String buildLinkedInUrl(String input) {
    // If already a full HTTPS URL, return as-is
    if (input.startsWith('https://')) {
      return input;
    }

    // If HTTP URL, upgrade to HTTPS
    if (input.startsWith('http://')) {
      return input.replaceFirst('http://', 'https://');
    }

    // If starts with www.linkedin.com or linkedin.com, add https://
    if (input.startsWith('www.linkedin.com/in/') ||
        input.startsWith('linkedin.com/in/')) {
      return 'https://$input';
    }

    // If it's just a username, build full LinkedIn URL
    if (RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(input)) {
      return 'https://www.linkedin.com/in/$input';
    }

    // Fallback: treat as username
    return 'https://www.linkedin.com/in/$input';
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

  /// Validate study year (1-10)
  static bool isValidStudyYear(int? studyYear) {
    if (studyYear == null) return true; // Optional field
    return studyYear >= 1 && studyYear <= 10;
  }

  /// Validate required string field (not empty)
  static bool isRequiredFieldValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
