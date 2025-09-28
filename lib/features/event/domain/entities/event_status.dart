/// Status of an event from user's perspective
enum EventStatus {
  notBooked,
  booked,
  ticketUsed;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case EventStatus.notBooked:
        return 'Not Booked';
      case EventStatus.booked:
        return 'Booked';
      case EventStatus.ticketUsed:
        return 'Attended';
    }
  }

  /// Check if user has booked this event (includes ticket used)
  bool get isBooked =>
      this == EventStatus.booked || this == EventStatus.ticketUsed;

  /// Check if ticket has been used for this event
  bool get hasAttended => this == EventStatus.ticketUsed;
}
