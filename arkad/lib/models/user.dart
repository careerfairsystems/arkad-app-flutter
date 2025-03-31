class User {
  final int id;
  final String email;
  final String? firstName;
  final String? lastName;
  final bool isStudent;
  final String? cv;
  final String? profilePicture;
  final String? programme;
  final String? linkedin;
  final String? masterTitle;
  final int? studyYear;
  final bool isActive;
  final bool isStaff;
  final String? foodPreferences;
  final bool isVerified; // New field for verification status

  static const String _baseMediaUrl =
      "https://staging.backend.arkadtlth.se/media/";

  User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.isStudent,
    this.cv,
    this.profilePicture,
    this.programme,
    this.linkedin,
    this.masterTitle,
    this.studyYear,
    required this.isActive,
    required this.isStaff,
    this.foodPreferences,
    bool? isVerified, // Optional parameter with default calculation
  }) : this.isVerified = isVerified ??
            _calculateVerificationStatus(
                firstName,
                lastName,
                cv,
                profilePicture,
                programme,
                linkedin,
                masterTitle,
                studyYear,
                foodPreferences);

  // Helper method to calculate verification status based on required fields
  static bool _calculateVerificationStatus(
      String? firstName,
      String? lastName,
      String? cv,
      String? profilePicture,
      String? programme,
      String? linkedin,
      String? masterTitle,
      int? studyYear,
      String? foodPreferences) {
    return firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty &&
        cv != null &&
        cv.isNotEmpty &&
        profilePicture != null &&
        profilePicture.isNotEmpty &&
        programme != null &&
        programme.isNotEmpty &&
        linkedin != null &&
        linkedin.isNotEmpty &&
        masterTitle != null &&
        masterTitle.isNotEmpty &&
        studyYear != null &&
        foodPreferences != null &&
        foodPreferences.isNotEmpty;
  }

  static String _prependMediaUrl(String? url) {
    if (url == null) {
      return "";
    }
    return _baseMediaUrl + url;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // Extract all user fields
    String? firstName = json['first_name'];
    String? lastName = json['last_name'];
    String? cv = json['cv'];
    String? profilePicture = json['profile_picture'];
    String? programme = json['programme'];
    String? linkedin = json['linkedin'];
    String? masterTitle = json['master_title'];
    int? studyYear = json['study_year'];
    String? foodPreferences = json['food_preferences'];

    // Process media URLs
    String? processedCv = cv != null ? _prependMediaUrl(cv) : null;
    String? processedProfilePic =
        profilePicture != null ? _prependMediaUrl(profilePicture) : null;

    // Calculate verification status from fields
    bool isVerified = _calculateVerificationStatus(
        firstName,
        lastName,
        processedCv,
        processedProfilePic,
        programme,
        linkedin,
        masterTitle,
        studyYear,
        foodPreferences);

    return User(
      id: json['id'],
      email: json['email'],
      firstName: firstName,
      lastName: lastName,
      isStudent: json['is_student'] ?? true,
      cv: processedCv,
      profilePicture: processedProfilePic,
      programme: programme,
      linkedin: linkedin,
      masterTitle: masterTitle,
      studyYear: studyYear,
      isActive: json['is_active'] ?? true,
      isStaff: json['is_staff'] ?? false,
      foodPreferences: foodPreferences,
      isVerified: isVerified, // Set verification status
    );
  }

  // Get missing required fields
  List<String> getMissingFields() {
    List<String> missingFields = [];

    if (firstName == null || firstName!.isEmpty)
      missingFields.add('First Name');
    if (lastName == null || lastName!.isEmpty) missingFields.add('Last Name');
    if (cv == null || cv!.isEmpty) missingFields.add('CV');
    if (profilePicture == null || profilePicture!.isEmpty)
      missingFields.add('Profile Picture');
    if (programme == null || programme!.isEmpty) missingFields.add('Programme');
    if (linkedin == null || linkedin!.isEmpty) missingFields.add('LinkedIn');
    if (masterTitle == null || masterTitle!.isEmpty)
      missingFields.add('Master Title');
    if (studyYear == null) missingFields.add('Study Year');
    if (foodPreferences == null || foodPreferences!.isEmpty)
      missingFields.add('Food Preferences');

    return missingFields;
  }
}
