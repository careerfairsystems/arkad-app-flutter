import 'package:arkad_api/arkad_api.dart' as api;
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../domain/entities/field_configuration.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';

/// Mapper for converting between API DTOs and domain entities
class StudentSessionMapper {
  const StudentSessionMapper();

  /// Convert API StudentSessionNormalUserSchema to StudentSession domain entity
  /// Note: companyName and logoUrl should be populated by repository layer using company data
  StudentSession fromApiStudentSession(
    api.StudentSessionNormalUserSchema apiSession, {
    String? companyName,
    String? logoUrl,
  }) {
    return StudentSession(
      id: apiSession.id,
      companyId: apiSession.companyId,
      companyName: companyName ?? 'Unknown Company',
      isAvailable: apiSession.available,
      bookingCloseTime: apiSession.bookingCloseTime,
      userStatus: _mapUserStatusToStudentSessionStatus(apiSession.userStatus),
      logoUrl: logoUrl,
      description: apiSession.description,
      disclaimer: apiSession.disclaimer,
      fieldConfigurations: _mapFieldModifications(
        apiSession.fieldModifications.toList(),
      ),
    );
  }

  /// Convert API StudentSessionApplicationOutSchema to domain entity
  StudentSessionApplication fromApiApplicationOut(
    api.StudentSessionApplicationOutSchema apiApplication,
    int companyId, {
    String? companyName,
  }) {
    return StudentSessionApplication(
      companyId: companyId,
      companyName: companyName ?? 'Unknown Company',
      motivationText: apiApplication.motivationText ?? '',
      status:
          ApplicationStatus.pending, // Default status for ApplicationOut schema
      cvUrl: apiApplication.cv,
    );
  }

  /// Convert StudentSessionNormalUserSchema to StudentSessionApplication (for my applications)
  StudentSessionApplication fromApiStudentSessionToApplication(
    api.StudentSessionNormalUserSchema apiSession, {
    String? companyName,
  }) {
    return StudentSessionApplication(
      companyId: apiSession.companyId,
      companyName: companyName ?? 'Unknown Company',
      motivationText: '', // Motivation text not available in this schema
      status:
          _mapUserStatus(apiSession.userStatus) ?? ApplicationStatus.pending,
    );
  }

  /// Convert StudentSessionApplicationParams to API StudentSessionApplicationSchema
  api.StudentSessionApplicationSchema toApiApplicationSchema(dynamic params) {
    return api.StudentSessionApplicationSchema(
      (b) =>
          b
            ..companyId = params.companyId
            ..motivationText = params.motivationText
            ..programme = params.programme
            ..linkedin = params.linkedin
            ..masterTitle = params.masterTitle
            ..studyYear = params.studyYear,
    );
  }

  /// Convert API TimeslotSchemaUser to domain entity
  Timeslot fromApiTimeslotUser(
    api.TimeslotSchemaUser apiTimeslot,
    int companyId,
  ) {
    final mappedStatus = _mapTimeslotStatus(apiTimeslot.status);

    return Timeslot(
      id: apiTimeslot.id,
      companyId: companyId,
      startTime: apiTimeslot.startTime,
      durationMinutes: apiTimeslot.duration,
      status: mappedStatus,
    );
  }


  /// Helper method to map API user status to domain StudentSessionStatus
  StudentSessionStatus? _mapUserStatusToStudentSessionStatus(
    api.StudentSessionNormalUserSchemaUserStatusEnum? apiStatus,
  ) {
    if (apiStatus == null) return null;

    switch (apiStatus) {
      case api.StudentSessionNormalUserSchemaUserStatusEnum.accepted:
        return StudentSessionStatus.accepted;
      case api.StudentSessionNormalUserSchemaUserStatusEnum.rejected:
        return StudentSessionStatus.rejected;
      case api.StudentSessionNormalUserSchemaUserStatusEnum.pending:
        return StudentSessionStatus.pending;
      default:
        return null;
    }
  }

  /// Helper method to map API user status to domain ApplicationStatus
  ApplicationStatus? _mapUserStatus(
    api.StudentSessionNormalUserSchemaUserStatusEnum? apiStatus,
  ) {
    if (apiStatus == null) return null;

    switch (apiStatus) {
      case api.StudentSessionNormalUserSchemaUserStatusEnum.accepted:
        return ApplicationStatus.accepted;
      case api.StudentSessionNormalUserSchemaUserStatusEnum.rejected:
        return ApplicationStatus.rejected;
      case api.StudentSessionNormalUserSchemaUserStatusEnum.pending:
        return ApplicationStatus.pending;
      default:
        return null;
    }
  }

  /// Helper method to map API timeslot status to domain TimeslotStatus
  TimeslotStatus _mapTimeslotStatus(
    api.TimeslotSchemaUserStatusEnum apiStatus,
  ) {
    switch (apiStatus) {
      case api.TimeslotSchemaUserStatusEnum.free:
        return TimeslotStatus.free;
      case api.TimeslotSchemaUserStatusEnum.bookedByCurrentUser:
        return TimeslotStatus.bookedByCurrentUser;
      default:
        // Log unknown status to Sentry for production monitoring
        Sentry.logger.error(
          'Unknown timeslot status encountered in API response',
          attributes: {
            'component': SentryLogAttribute.string('StudentSessionMapper'),
            'api_status': SentryLogAttribute.string(apiStatus.toString()),
            'default_action': SentryLogAttribute.string('defaulting_to_free'),
          },
        );
        // Return safe default to prevent exposing technical details
        return TimeslotStatus.free;
    }
  }

  /// Convert API field modifications to domain field configurations
  List<FieldConfiguration> _mapFieldModifications(
    List<api.FieldModificationSchema> apiFieldModifications,
  ) {
    return apiFieldModifications.map((apiField) {
      return FieldConfiguration(
        fieldName: _normalizeFieldName(apiField.name),
        level: _mapFieldLevel(apiField.fieldLevel),
      );
    }).toList();
  }

  /// Normalize API field names from snake_case to camelCase
  String _normalizeFieldName(String apiFieldName) {
    switch (apiFieldName) {
      case 'master_title':
        return 'masterTitle';
      case 'study_year':
        return 'studyYear';
      case 'motivation_text':
        return 'motivationText';
      case 'programme':
        return 'programme';
      case 'linkedin':
        return 'linkedin';
      case 'cv':
        return 'cv';
      default:
        // Convert snake_case to camelCase for unknown fields
        return apiFieldName.replaceAllMapped(
          RegExp(r'_([a-z])'),
          (match) => match.group(1)!.toUpperCase(),
        );
    }
  }

  /// Map API FieldLevel to domain FieldLevel
  FieldLevel _mapFieldLevel(api.FieldLevel? apiFieldLevel) {
    if (apiFieldLevel == null) return FieldLevel.required;

    switch (apiFieldLevel) {
      case api.FieldLevel.required_:
        return FieldLevel.required;
      case api.FieldLevel.optional:
        return FieldLevel.optional;
      case api.FieldLevel.hidden:
        return FieldLevel.hidden;
      default:
        // Default to required for unknown values to ensure form validation
        return FieldLevel.required;
    }
  }
}
