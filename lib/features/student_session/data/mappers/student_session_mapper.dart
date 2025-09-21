import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';

/// Mapper for converting between API DTOs and domain entities
class StudentSessionMapper {
  const StudentSessionMapper();

  /// Convert API StudentSessionNormalUserSchema to StudentSession domain entity
  /// Note: companyName should be populated by repository layer using company data
  StudentSession fromApiStudentSession(
    StudentSessionNormalUserSchema apiSession, {
    String? companyName,
  }) {
    return StudentSession(
      id: apiSession.id,
      companyId: apiSession.companyId,
      companyName: companyName ?? 'Unknown Company',
      isAvailable: apiSession.available,
      bookingCloseTime: apiSession.bookingCloseTime,
      userStatus: _mapUserStatusToStudentSessionStatus(apiSession.userStatus),
    );
  }

  /// Convert API StudentSessionApplicationOutSchema to domain entity
  StudentSessionApplication fromApiApplicationOut(
    StudentSessionApplicationOutSchema apiApplication,
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
    StudentSessionNormalUserSchema apiSession, {
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
  StudentSessionApplicationSchema toApiApplicationSchema(dynamic params) {
    return StudentSessionApplicationSchema(
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
  Timeslot fromApiTimeslotUser(TimeslotSchemaUser apiTimeslot, int companyId) {
    final mappedStatus = _mapTimeslotStatus(apiTimeslot.status);
    
    return Timeslot(
      id: apiTimeslot.id,
      companyId: companyId,
      startTime: apiTimeslot.startTime,
      durationMinutes: apiTimeslot.duration,
      status: mappedStatus,
    );
  }

  /// Convert API TimeslotSchema to domain entity (legacy support)
  Timeslot fromApiTimeslot(TimeslotSchema apiTimeslot, int companyId) {
    return Timeslot(
      id: apiTimeslot.id,
      companyId: companyId,
      startTime: apiTimeslot.startTime,
      durationMinutes: apiTimeslot.duration,
      status: TimeslotStatus.free, // Default to free for legacy timeslots
    );
  }

  /// Helper method to map API user status to domain StudentSessionStatus
  StudentSessionStatus? _mapUserStatusToStudentSessionStatus(
    StudentSessionNormalUserSchemaUserStatusEnum? apiStatus,
  ) {
    if (apiStatus == null) return null;

    switch (apiStatus) {
      case StudentSessionNormalUserSchemaUserStatusEnum.accepted:
        return StudentSessionStatus.accepted;
      case StudentSessionNormalUserSchemaUserStatusEnum.rejected:
        return StudentSessionStatus.rejected;
      case StudentSessionNormalUserSchemaUserStatusEnum.pending:
        return StudentSessionStatus.pending;
      default:
        return null;
    }
  }

  /// Helper method to map API user status to domain ApplicationStatus
  ApplicationStatus? _mapUserStatus(
    StudentSessionNormalUserSchemaUserStatusEnum? apiStatus,
  ) {
    if (apiStatus == null) return null;

    switch (apiStatus) {
      case StudentSessionNormalUserSchemaUserStatusEnum.accepted:
        return ApplicationStatus.accepted;
      case StudentSessionNormalUserSchemaUserStatusEnum.rejected:
        return ApplicationStatus.rejected;
      case StudentSessionNormalUserSchemaUserStatusEnum.pending:
        return ApplicationStatus.pending;
      default:
        return null;
    }
  }

  /// Helper method to map API timeslot status to domain TimeslotStatus
  TimeslotStatus _mapTimeslotStatus(
    TimeslotSchemaUserStatusEnum apiStatus,
  ) {
    switch (apiStatus) {
      case TimeslotSchemaUserStatusEnum.free:
        return TimeslotStatus.free;
      case TimeslotSchemaUserStatusEnum.bookedByCurrentUser:
        return TimeslotStatus.bookedByCurrentUser;
      default:
        throw ArgumentError('Unknown timeslot status: $apiStatus');
    }
  }
}
