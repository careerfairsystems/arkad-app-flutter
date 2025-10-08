/// Domain validation service for form validation
class ValidationService {
  // Regular expressions for validation
  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final _upperCaseRegExp = RegExp(r'[A-Z]');
  static final _lowerCaseRegExp = RegExp(r'[a-z]');
  static final _numberRegExp = RegExp(r'[0-9]');

  static const int passwordMinLength = 8;

  /// Validates an email address
  static bool isValidEmail(String email) {
    return _emailRegExp.hasMatch(email.trim());
  }

  /// Validates email for forms
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  /// Validates password for login (checks not empty and minimum length)
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < passwordMinLength) {
      return 'Password must be at least $passwordMinLength characters';
    }
    return null;
  }

  /// Check password strength criteria
  static Map<String, bool> checkPasswordStrength(String password) {
    return {
      'minLength': password.length >= passwordMinLength,
      'hasUppercase': _upperCaseRegExp.hasMatch(password),
      'hasLowercase': _lowerCaseRegExp.hasMatch(password),
      'hasNumber': _numberRegExp.hasMatch(password),
    };
  }

  /// Check if password is strong (meets all criteria)
  static bool isStrongPassword(String password) {
    final strengthChecks = checkPasswordStrength(password);
    return strengthChecks.values.every((isValid) => isValid);
  }

  /// Check if passwords match
  static bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }

  /// Validate LinkedIn profile URL (strict - full URLs only)
  /// Accepts only full LinkedIn URLs:
  /// - https://www.linkedin.com/in/username/
  /// - https://linkedin.com/in/username/
  /// - www.linkedin.com/in/username/
  /// - linkedin.com/in/username/
  static bool isValidLinkedInUrl(String url) {
    final patterns = [
      r'^https://www\.linkedin\.com/in/[a-zA-Z0-9_-]+/?$',
      r'^https://linkedin\.com/in/[a-zA-Z0-9_-]+/?$',
      r'^www\.linkedin\.com/in/[a-zA-Z0-9_-]+/?$',
      r'^linkedin\.com/in/[a-zA-Z0-9_-]+/?$',
    ];
    return patterns.any(
      (pattern) => RegExp(pattern, caseSensitive: false).hasMatch(url.trim()),
    );
  }

  /// Build normalized LinkedIn URL from user input
  /// Converts various LinkedIn URL formats to canonical form:
  /// - 'www.linkedin.com/in/user' → 'https://www.linkedin.com/in/user'
  /// - 'linkedin.com/in/user' → 'https://www.linkedin.com/in/user'
  /// - 'https://linkedin.com/in/user' → 'https://www.linkedin.com/in/user'
  /// If not a valid LinkedIn URL format, returns input unchanged (validation will fail)
  static String buildLinkedInUrl(String input) {
    final trimmed = input.trim();

    // Already in canonical form or https://linkedin.com format
    if (trimmed.startsWith('https://www.linkedin.com/in/') ||
        trimmed.startsWith('https://linkedin.com/in/')) {
      return trimmed.endsWith('/') ? trimmed : '$trimmed/';
    }

    // Add https:// prefix to www.linkedin.com or linkedin.com URLs
    if (trimmed.startsWith('www.linkedin.com/in/') ||
        trimmed.startsWith('linkedin.com/in/')) {
      final normalized = 'https://$trimmed';
      return normalized.endsWith('/') ? normalized : '$normalized/';
    }

    // If not a valid format, return as-is (validation will fail)
    return trimmed;
  }

  /// Validate study year (1-5 for bachelor's
  /// Returns true if null (optional field) or within valid range
  static bool isValidStudyYear(int? studyYear) {
    if (studyYear == null) return true; // Optional field
    return studyYear >= 1 && studyYear <= 5;
  }

  /// Validate required string field (not null and not empty after trimming)
  static bool isRequiredFieldValid(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}
