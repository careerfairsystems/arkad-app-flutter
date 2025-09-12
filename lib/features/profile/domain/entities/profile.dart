import 'programme.dart';

/// Domain entity representing user profile data
class Profile {
  const Profile({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.foodPreferences,
    this.programme,
    this.studyYear,
    this.masterTitle,
    this.linkedin,
    this.profilePictureUrl,
    this.cvUrl,
  });

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String? foodPreferences;
  final Programme? programme;
  final int? studyYear;
  final String? masterTitle;
  final String? linkedin;
  final String? profilePictureUrl;
  final String? cvUrl;

  /// Check if profile has all required fields completed
  bool get isComplete =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty;

  /// Includes optional fields for better user experience
  double get completionPercentage {
    int completed = 0;
    int total = 7; // firstName, lastName, foodPreferences, programme, linkedin, picture, cv

    // Required fields
    if (firstName.isNotEmpty) completed++;
    if (lastName.isNotEmpty) completed++;
    
    // Optional fields (improve completion score)
    if (foodPreferences?.isNotEmpty ?? false) completed++;
    if (programme != null) completed++;
    if (linkedin?.isNotEmpty ?? false) completed++;
    if (profilePictureUrl?.isNotEmpty ?? false) completed++;
    if (cvUrl?.isNotEmpty ?? false) completed++;

    return completed / total;
  }

  /// Get missing required fields
  /// Only first name and last name are required for profile completion
  List<String> get missingRequiredFields {
    final missing = <String>[];
    if (firstName.isEmpty) missing.add('First Name');
    if (lastName.isEmpty) missing.add('Last Name');
    return missing;
  }

  /// Get user's full name
  String get fullName => '$firstName $lastName'.trim();

  /// Check if user has LinkedIn profile
  bool get hasLinkedIn => linkedin?.isNotEmpty ?? false;

  /// Check if user has profile picture
  bool get hasProfilePicture => profilePictureUrl?.isNotEmpty ?? false;

  /// Check if user has CV uploaded
  bool get hasCV => cvUrl?.isNotEmpty ?? false;

  /// Create a copy with updated values
  Profile copyWith({
    int? id,
    String? email,
    String? firstName,
    String? lastName,
    String? foodPreferences,
    Programme? programme,
    int? studyYear,
    String? masterTitle,
    String? linkedin,
    String? profilePictureUrl,
    String? cvUrl,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      foodPreferences: foodPreferences,
      programme: programme ?? this.programme,
      studyYear: studyYear ?? this.studyYear,
      masterTitle: masterTitle,
      linkedin: linkedin,
      profilePictureUrl: profilePictureUrl,
      cvUrl: cvUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, email);

  @override
  String toString() => 'Profile(id: $id, email: $email, name: $fullName)';
}
