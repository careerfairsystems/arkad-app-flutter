import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/event_attendee.dart';

/// Mapper for converting EventUserInformation to EventAttendee
class EventAttendeeMapper {
  /// Convert API schema to domain entity
  EventAttendee fromApiSchema(EventUserInformation schema) {
    return EventAttendee(
      fullName: schema.fullName,
      foodPreferences: schema.foodPreferences,
      hasBeenScanned: schema.ticketUsed,
    );
  }

  /// Convert domain entity to API schema
  EventUserInformation toApiSchema(EventAttendee attendee) {
    return EventUserInformation(
      (builder) => builder
        ..fullName = attendee.fullName
        ..foodPreferences = attendee.foodPreferences
        ..ticketUsed = attendee.hasBeenScanned
        ..userId = 0, // userId is required by API but not used in this context
    );
  }
}
