import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/signup_data.dart';

/// Mapper class for converting between SignupData and API DTOs
class SignupMapper {
  /// Convert SignupData to SignupSchema DTO
  static SignupSchema toSignupDto(SignupData data) {
    return SignupSchema(
      (b) =>
          b
            ..email = data.email
            ..password = data.password
            ..firstName = data.firstName
            ..lastName = data.lastName
            ..foodPreferences = data.foodPreferences,
    );
  }

  /// Convert SignupData to CompleteSignupSchema DTO
  static CompleteSignupSchema toCompleteSignupDto({
    required String token,
    required String code,
    required SignupData data,
  }) {
    return CompleteSignupSchema(
      (b) =>
          b
            ..token = token
            ..code = code
            ..email = data.email
            ..password = data.password
            ..firstName = data.firstName
            ..lastName = data.lastName
            ..foodPreferences = data.foodPreferences,
    );
  }
}
