import 'user_event_info.dart';

/// Status enum for ticket verification
enum TicketVerificationStatus {
  /// Ticket was already used or user doesn't have a ticket for this event
  alreadyUsed,

  /// Ticket was successfully consumed/verified
  consumed,
}

/// Result of ticket verification operation
class TicketVerificationResult {
  final TicketVerificationStatus status;
  final String uuid;
  final int eventId;
  final UserEventInfo? userInfo;

  const TicketVerificationResult({
    required this.status,
    required this.uuid,
    required this.eventId,
    this.userInfo,
  });

  @override
  String toString() =>
      'TicketVerificationResult(status: $status, uuid: $uuid, eventId: $eventId)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TicketVerificationResult &&
        other.status == status &&
        other.uuid == uuid &&
        other.eventId == eventId &&
        other.userInfo == userInfo;
  }

  @override
  int get hashCode => Object.hash(status, uuid, eventId, userInfo);
}
