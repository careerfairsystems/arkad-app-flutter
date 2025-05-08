// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  isStudent: json['isStudent'] as bool,
  cv: json['cv'] as String?,
  profilePicture: json['profilePicture'] as String?,
  programme: json['programme'] as String?,
  linkedin: json['linkedin'] as String?,
  masterTitle: json['masterTitle'] as String?,
  studyYear: (json['studyYear'] as num?)?.toInt(),
  isActive: json['isActive'] as bool,
  isStaff: json['isStaff'] as bool,
  foodPreferences: json['foodPreferences'] as String?,
  isVerified: json['isVerified'] as bool?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'isStudent': instance.isStudent,
  'cv': instance.cv,
  'profilePicture': instance.profilePicture,
  'programme': instance.programme,
  'linkedin': instance.linkedin,
  'masterTitle': instance.masterTitle,
  'studyYear': instance.studyYear,
  'isActive': instance.isActive,
  'isStaff': instance.isStaff,
  'foodPreferences': instance.foodPreferences,
  'isVerified': instance.isVerified,
};
