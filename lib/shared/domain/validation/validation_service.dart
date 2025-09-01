/// Domain validation service for form validation
class ValidationService {
  // Regular expressions for validation
  static final _emailRegExp = RegExp(r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+');
  static final _upperCaseRegExp = RegExp(r'[A-Z]');
  static final _lowerCaseRegExp = RegExp(r'[a-z]');
  static final _numberRegExp = RegExp(r'[0-9]');
  static final _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

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

  /// Validates password for login (just checks if not empty)
  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
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
      'hasSpecialChar': _specialCharRegExp.hasMatch(password),
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
}