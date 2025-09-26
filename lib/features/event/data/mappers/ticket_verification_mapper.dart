import 'package:arkad_api/arkad_api.dart';

import '../../domain/entities/ticket_verification_result.dart';
import '../../domain/entities/user_event_info.dart';

/// Mapper for converting API ticket response to domain entities
class TicketVerificationMapper {
  /// Convert TicketSchema to TicketVerificationResult
  /// This is used when the API call is successful and returns ticket data
  TicketVerificationResult fromSuccessfulTicketSchema(TicketSchema schema) {
    return TicketVerificationResult(
      status:
          schema.used
              ? TicketVerificationStatus.alreadyUsed
              : TicketVerificationStatus.consumed,
      uuid: schema.uuid,
      eventId: schema.eventId,
      userInfo: _mapUserEventInfo(schema.user),
    );
  }

  /// Create TicketVerificationResult for "already used" case
  /// This is used when the API returns 404 with "You do not have a ticket for this event"
  TicketVerificationResult createAlreadyUsedResult(String uuid, int eventId) {
    return TicketVerificationResult(
      status: TicketVerificationStatus.alreadyUsed,
      uuid: uuid,
      eventId: eventId,
    );
  }

  /// Convert UserEventInformationSchema to UserEventInfo domain entity
  UserEventInfo _mapUserEventInfo(UserEventInformationSchema schema) {
    return UserEventInfo(
      id: schema.id,
      firstName: schema.firstName,
      lastName: schema.lastName,
      foodPreferences: schema.foodPreferences,
    );
  }
}
