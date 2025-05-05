// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      isStudent: json['is_student'] as bool,
      cv: json['cv'] as String?,
      profilePicture: json['profile_picture'] as String?,
      programme: json['programme'] as String?,
      linkedin: json['linkedin'] as String?,
      masterTitle: json['master_title'] as String?,
      studyYear: (json['study_year'] as num?)?.toInt(),
      isActive: json['is_active'] as bool,
      isStaff: json['is_staff'] as bool,
      foodPreferences: json['food_preferences'] as String?,
      isVerified: json['is_verified'] as bool?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'is_student': instance.isStudent,
      'cv': instance.cv,
      'profile_picture': instance.profilePicture,
      'programme': instance.programme,
      'linkedin': instance.linkedin,
      'master_title': instance.masterTitle,
      'study_year': instance.studyYear,
      'is_active': instance.isActive,
      'is_staff': instance.isStaff,
      'food_preferences': instance.foodPreferences,
      'is_verified': instance.isVerified,
    };
