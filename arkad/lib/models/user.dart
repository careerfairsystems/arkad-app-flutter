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
  });

  static String _prependMediaUrl(String? url) {
    if (url == null) {
      return "";
    }
    return _baseMediaUrl + url;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      isStudent: json['is_student'] ?? true,
      cv: _prependMediaUrl(json['cv']),
      profilePicture: _prependMediaUrl(json['profile_picture']),
      programme: json['programme'],
      linkedin: json['linkedin'],
      masterTitle: json['master_title'],
      studyYear: json['study_year'],
      isActive: json['is_active'] ?? true,
      isStaff: json['is_staff'] ?? false,
      foodPreferences: json['food_preferences'],
    );
  }
}
