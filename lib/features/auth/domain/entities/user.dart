/// Domain entity representing a user
class User {
  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isStudent,
    required this.isActive,
    required this.isStaff,
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
  final bool isStudent;
  final bool isActive;
  final bool isStaff;
  final String? foodPreferences;
  final String? programme;
  final int? studyYear;
  final String? masterTitle;
  final String? linkedin;
  final String? profilePictureUrl;
  final String? cvUrl;

  /// Check if user has completed required profile fields
  bool get hasCompleteProfile =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      (foodPreferences?.isNotEmpty ?? false);

  /// Get user's full name
  String get fullName => '$firstName $lastName'.trim();

  /// Check if user has LinkedIn profile
  bool get hasLinkedIn => linkedin?.isNotEmpty ?? false;

  /// Check if user has profile picture
  bool get hasProfilePicture => profilePictureUrl?.isNotEmpty ?? false;

  /// Check if user has CV
  bool get hasCV => cvUrl?.isNotEmpty ?? false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          firstName == other.firstName &&
          lastName == other.lastName &&
          isStudent == other.isStudent &&
          isActive == other.isActive &&
          isStaff == other.isStaff;

  @override
  int get hashCode =>
      Object.hash(id, email, firstName, lastName, isStudent, isActive, isStaff);

  @override
  String toString() => 'User(id: $id)';
}
