/// Utility class for form validation in authentication screens
class ValidationUtils {
  // Regular expressions for validation
  static final _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._-]+@[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)*\.[a-zA-Z]+$',
  );
  static final _upperCaseRegExp = RegExp(r'[A-Z]');
  static final _lowerCaseRegExp = RegExp(r'[a-z]');
  static final _numberRegExp = RegExp(r'[0-9]');
  static final _specialCharRegExp = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  static const int passwordMinLength = 8;

  /// Validates an email address
  static bool isValidEmail(String email) {
    return _emailRegExp.hasMatch(email.trim());
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!isValidEmail(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validateLoginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    return null;
  }

  static Map<String, bool> checkPasswordStrength(String password) {
    return {
      'minLength': password.length >= passwordMinLength,
      'hasUppercase': _upperCaseRegExp.hasMatch(password),
      'hasLowercase': _lowerCaseRegExp.hasMatch(password),
      'hasNumber': _numberRegExp.hasMatch(password),
      'hasSpecialChar': _specialCharRegExp.hasMatch(password),
    };
  }

  static bool isStrongPassword(String password) {
    final strengthChecks = checkPasswordStrength(password);
    return strengthChecks.values.every((isValid) => isValid);
  }

  static bool doPasswordsMatch(String password, String confirmPassword) {
    return password == confirmPassword;
  }
}
