import 'package:arkad_api/arkad_api.dart';
import '../../domain/entities/event.dart';

/// Mapper for converting between Event domain entity and EventSchema DTO
class EventMapper {
  /// Convert EventSchema DTO to Event domain entity
  /// Note: EventSchema doesn't include ID, so we need to provide it separately
  Event fromApiSchema(EventSchema schema) {
    return Event(
      id: schema.id,
      title: schema.name,
      description: schema.description,
      startTime: schema.startTime,
      endTime: schema.endTime,
      location: schema.location,
      type: _mapEventType(schema.type),
      isRegistrationRequired: schema.capacity > 0,
      maxParticipants: schema.capacity > 0 ? schema.capacity : null,
      currentParticipants: schema.numberBooked,
    );
  }

  /// Convert Event domain entity to EventSchema DTO
  /// Note: This is mainly for creating new events (if supported in future)
  EventSchema toApiSchema(Event event) {
    return EventSchema(
      (b) =>
          b
            ..name = event.title
            ..description = event.description
            ..type = _mapEventTypeToString(event.type)
            ..location = event.location
            ..language =
                'en' // Default language
            ..startTime = event.startTime
            ..endTime = event.endTime
            ..capacity = event.maxParticipants ?? 0
            ..numberBooked = event.currentParticipants
            ..companyId = null,
    );
  }

  /// Map string event type from API to EventType enum
  EventType _mapEventType(String apiType) {
    switch (apiType.toLowerCase()) {
      case 'presentation':
        return EventType.presentation;
      case 'workshop':
        return EventType.workshop;
      case 'networking':
        return EventType.networking;
      case 'panel':
      case 'panel discussion':
        return EventType.panel;
      case 'career fair':
      case 'careerfair':
        return EventType.careerFair;
      case 'social':
      case 'social event':
        return EventType.social;
      default:
        // Default to networking for unknown types
        return EventType.networking;
    }
  }

  /// Map EventType enum to string for API
  String _mapEventTypeToString(EventType eventType) {
    switch (eventType) {
      case EventType.presentation:
        return 'presentation';
      case EventType.workshop:
        return 'workshop';
      case EventType.networking:
        return 'networking';
      case EventType.panel:
        return 'panel';
      case EventType.careerFair:
        return 'career fair';
      case EventType.social:
        return 'social';
    }
  }
}
