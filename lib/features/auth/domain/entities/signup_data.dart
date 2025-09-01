/// Value object for signup data
class SignupData {
  const SignupData({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
    this.foodPreferences,
  });

  final String email;
  final String password;
  final String? firstName;
  final String? lastName;
  final String? foodPreferences;

  /// Check if signup data is valid
  bool get isValid =>
      email.isNotEmpty &&
      password.isNotEmpty &&
      _isValidEmail(email) &&
      password.length >= 8;

  /// Check if email format is valid
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  /// Create a copy with updated values
  SignupData copyWith({
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? foodPreferences,
  }) {
    return SignupData(
      email: email ?? this.email,
      password: password ?? this.password,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      foodPreferences: foodPreferences ?? this.foodPreferences,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SignupData &&
          runtimeType == other.runtimeType &&
          email == other.email &&
          password == other.password &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          foodPreferences == other.foodPreferences;

  @override
  int get hashCode =>
      Object.hash(email, password, firstName, lastName, foodPreferences);

  @override
  String toString() => 'SignupData(email: $email)';
}