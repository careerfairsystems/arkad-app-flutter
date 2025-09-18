import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/student_session_application.dart';
import '../../domain/entities/timeslot.dart';

/// Mapper for converting between API DTOs and domain entities
class StudentSessionMapper {
  const StudentSessionMapper();

  /// Convert API StudentSessionApplicationOutSchema to domain entity
  StudentSessionApplication fromApiApplication(
    StudentSessionApplicationOutSchema apiApplication,
    String companyName,
  ) {
    return StudentSessionApplication(
      companyId: apiApplication.companyId,
      companyName: companyName,
      motivationText: apiApplication.motivationText ?? '',
      status: ApplicationStatus.pending, // Default status
    );
  }

  /// Convert domain entity to API StudentSessionApplicationSchema
  StudentSessionApplicationSchema toApiApplication(
    StudentSessionApplication application,
  ) {
    return StudentSessionApplicationSchema(
      (b) =>
          b
            ..companyId = application.companyId
            ..motivationText = application.motivationText
            ..programme = application.programme
            ..linkedin = application.linkedin
            ..masterTitle = application.masterTitle
            ..studyYear = application.studyYear,
    );
  }

  /// Convert API TimeslotSchema to domain entity
  Timeslot fromApiTimeslot(TimeslotSchema apiTimeslot) {
    return Timeslot(
      id: apiTimeslot.id,
      companyId: 0, // Will be set by the calling code
      startTime: apiTimeslot.startTime,
      endTime: apiTimeslot.startTime.add(
        const Duration(minutes: 30),
      ), // Default 30 min session
      maxParticipants: 10, // Default value
      currentParticipants: 0, // Default value
      isAvailable: true, // Default to available
    );
  }
}
