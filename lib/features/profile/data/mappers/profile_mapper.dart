import 'package:arkad_api/arkad_api.dart';

import '../../../../shared/data/url_utils.dart';
import '../../domain/entities/profile.dart';
import '../../domain/entities/programme.dart';

/// Mapper for converting between ProfileSchema DTO and Profile domain entity
class ProfileMapper {
  /// Convert ProfileSchema DTO to Profile domain entity
  static Profile fromDto(ProfileSchema dto) {
    return Profile(
      id: dto.id,
      email: dto.email,
      firstName: dto.firstName,
      lastName: dto.lastName,
      foodPreferences:
          dto.foodPreferences?.isEmpty == true ? null : dto.foodPreferences,
      programme: ProgrammeUtils.labelToProgramme(dto.programme),
      studyYear: dto.studyYear,
      masterTitle: dto.masterTitle?.isEmpty == true ? null : dto.masterTitle,
      linkedin: dto.linkedin?.isEmpty == true ? null : dto.linkedin,
      profilePictureUrl:
          dto.profilePicture?.isEmpty == true ? null : UrlUtils.buildFullUrl(dto.profilePicture),
      cvUrl: dto.cv?.isEmpty == true ? null : UrlUtils.buildFullUrl(dto.cv),
    );
  }

  /// Convert Profile domain entity to UpdateProfileSchema DTO
  static UpdateProfileSchema toUpdateDto(Profile profile) {
    return UpdateProfileSchema(
      (b) =>
          b
            ..firstName =
                profile.firstName.isNotEmpty ? profile.firstName : null
            ..lastName = profile.lastName.isNotEmpty ? profile.lastName : null
            ..programme = ProgrammeUtils.programmeToLabel(profile.programme)
            ..studyYear = profile.studyYear
            ..masterTitle =
                profile.masterTitle?.isNotEmpty == true
                    ? profile.masterTitle
                    : null
            ..linkedin =
                profile.linkedin?.isNotEmpty == true ? profile.linkedin : null
            ..foodPreferences =
                profile.foodPreferences?.isNotEmpty == true
                    ? profile.foodPreferences
                    : null,
    );
  }

}
