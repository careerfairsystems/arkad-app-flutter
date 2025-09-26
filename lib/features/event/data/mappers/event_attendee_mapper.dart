import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/event_attendee.dart';

/// Mapper for converting EventUserInformation to EventAttendee
class EventAttendeeMapper {
  /// Convert API schema to domain entity
  EventAttendee fromApiSchema(EventUserInformation schema) {
    return EventAttendee(
      fullName: schema.fullName,
      foodPreferences: schema.foodPreferences,
    );
  }

  /// Convert domain entity to API schema
  EventUserInformation toApiSchema(EventAttendee attendee) {
    return EventUserInformation(
      (builder) =>
          builder
            ..fullName = attendee.fullName
            ..foodPreferences = attendee.foodPreferences,
    );
  }
}
