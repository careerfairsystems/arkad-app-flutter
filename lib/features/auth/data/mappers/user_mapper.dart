import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/user.dart';

/// Mapper class for converting between User domain entity and ProfileSchema DTO
class UserMapper {
  /// Convert ProfileSchema DTO to User domain entity
  static User fromDto(ProfileSchema dto) {
    return User(
      id: dto.id,
      email: dto.email,
      firstName: dto.firstName,
      lastName: dto.lastName,
      isStudent: dto.isStudent,
      isActive: dto.isActive,
      isStaff: dto.isStaff,
      foodPreferences: dto.foodPreferences,
      programme: dto.programme,
      studyYear: dto.studyYear,
      masterTitle: dto.masterTitle,
      linkedin: dto.linkedin,
      profilePictureUrl: dto.profilePicture,
      cvUrl: dto.cv,
    );
  }

  /// Convert User domain entity to ProfileSchema DTO
  static ProfileSchema toDto(User user) {
    return ProfileSchema(
      (b) =>
          b
            ..id = user.id
            ..email = user.email
            ..firstName = user.firstName
            ..lastName = user.lastName
            ..isStudent = user.isStudent
            ..isActive = user.isActive
            ..isStaff = user.isStaff
            ..foodPreferences = user.foodPreferences
            ..programme = user.programme
            ..studyYear = user.studyYear
            ..masterTitle = user.masterTitle
            ..linkedin = user.linkedin
            ..profilePicture = user.profilePictureUrl
            ..cv = user.cvUrl,
    );
  }
}
