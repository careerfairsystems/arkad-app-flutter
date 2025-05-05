import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final int id;
  final String email;
  @JsonKey(name: 'first_name')
  final String? firstName;
  @JsonKey(name: 'last_name')
  final String? lastName;
  @JsonKey(name: 'is_student')
  final bool isStudent;
  final String? cv;
  @JsonKey(name: 'profile_picture')
  final String? profilePicture;
  final String? programme;
  final String? linkedin;
  @JsonKey(name: 'master_title')
  final String? masterTitle;
  @JsonKey(name: 'study_year')
  final int? studyYear;
  @JsonKey(name: 'is_active')
  final bool isActive;
  @JsonKey(name: 'is_staff')
  final bool isStaff;
  @JsonKey(name: 'food_preferences')
  final String? foodPreferences;
  @JsonKey(name: 'is_verified')
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
  }) : isVerified = isVerified ??
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
    // Only first name, last name, programme, study year, and food preferences are required
    return firstName != null &&
        firstName.isNotEmpty &&
        lastName != null &&
        lastName.isNotEmpty &&
        programme != null &&
        programme.isNotEmpty &&
        studyYear != null &&
        foodPreferences != null &&
        foodPreferences.isNotEmpty;
    // CV, profile picture, LinkedIn, and master title are no longer required
  }

  static String _prependMediaUrl(String? url) {
    if (url == null) {
      return "";
    }
    return _baseMediaUrl + url;
  }

  factory User.fromJson(Map<String, dynamic> json) {
    // First use the generated function as a base
    User user = _$UserFromJson(json);
    
    // Process media URLs (preserve existing functionality)
    String? processedCv = user.cv != null ? _prependMediaUrl(user.cv!) : null;
    String? processedProfilePic = user.profilePicture != null 
        ? _prependMediaUrl(user.profilePicture!) 
        : null;

    // Calculate verification status
    bool isVerified = _calculateVerificationStatus(
        user.firstName,
        user.lastName,
        processedCv,
        processedProfilePic,
        user.programme,
        user.linkedin,
        user.masterTitle,
        user.studyYear,
        user.foodPreferences);

    // Return a new User with the processed data
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
