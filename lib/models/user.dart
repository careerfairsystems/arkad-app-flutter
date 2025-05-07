import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
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
  final bool isVerified;

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
    bool? isVerified,
  }) : isVerified =
           isVerified ??
           _calculateVerificationStatus(
             firstName,
             lastName,
             cv,
             profilePicture,
             programme,
             linkedin,
             masterTitle,
             studyYear,
             foodPreferences,
           );

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
    String? foodPreferences,
  ) {
    return firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty &&
        programme != null &&
        programme.isNotEmpty &&
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
    User user = _$UserFromJson(json);

    String? processedCv = user.cv != null ? _prependMediaUrl(user.cv!) : null;
    String? processedProfilePic =
        user.profilePicture != null
            ? _prependMediaUrl(user.profilePicture!)
            : null;

    bool isVerified = _calculateVerificationStatus(
      user.firstName,
      user.lastName,
      processedCv,
      processedProfilePic,
      user.programme,
      user.linkedin,
      user.masterTitle,
      user.studyYear,
      user.foodPreferences,
    );

    return User(
      id: user.id,
      email: user.email,
      firstName: user.firstName,
      lastName: user.lastName,
      isStudent: user.isStudent,
      cv: processedCv,
      profilePicture: processedProfilePic,
      programme: user.programme,
      linkedin: user.linkedin,
      masterTitle: user.masterTitle,
      studyYear: user.studyYear,
      isActive: user.isActive,
      isStaff: user.isStaff,
      foodPreferences: user.foodPreferences,
      isVerified: isVerified,
    );
  }

  Map<String, dynamic> toJson() => _$UserToJson(this);

  // Get missing required fields
  List<String> getMissingFields() {
    List<String> missingFields = [];

    if (firstName == null || firstName!.isEmpty) {
      missingFields.add('First Name');
    }
    if (lastName == null || lastName!.isEmpty) missingFields.add('Last Name');
    if (programme == null || programme!.isEmpty) missingFields.add('Programme');
    if (studyYear == null) missingFields.add('Study Year');
    if (foodPreferences == null || foodPreferences!.isEmpty) {
      missingFields.add('Food Preferences');
    }

    // CV, profile picture, LinkedIn, and master title are no longer in missing fields list
    return missingFields;
  }
}
