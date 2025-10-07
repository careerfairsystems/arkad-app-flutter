import 'event_status.dart';

/// Domain entity representing an event
class Event {
  final int id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final String location;
  final String? imageUrl;
  final EventType type;
  final bool isRegistrationRequired;
  final int? maxParticipants;
  final int currentParticipants;
  final EventStatus? status;
  final DateTime bookingClosesAt;

  const Event({
    required this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.location,
    this.imageUrl,
    required this.type,
    this.isRegistrationRequired = false,
    this.maxParticipants,
    this.currentParticipants = 0,
    this.status,
    required this.bookingClosesAt,
  });

  /// Create a copy with updated values
  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? imageUrl,
    EventType? type,
    bool? isRegistrationRequired,
    int? maxParticipants,
    int? currentParticipants,
    EventStatus? status,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      type: type ?? this.type,
      isRegistrationRequired:
          isRegistrationRequired ?? this.isRegistrationRequired,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      status: status ?? this.status,
      bookingClosesAt: bookingClosesAt,
    );
  }

  /// Check if event has started
  bool get hasStarted => DateTime.now().isAfter(startTime);

  /// Check if event has ended
  bool get hasEnded => DateTime.now().isAfter(endTime);

  /// Check if event is currently happening
  bool get isOngoing => hasStarted && !hasEnded;

  bool get bookingDeadlineClosed => DateTime.now().isAfter(bookingClosesAt);

  /// Check if registration is still available
  bool get canRegister {
    if (!isRegistrationRequired) return false;
    if (hasStarted) return false;
    if (status?.isBooked == true) return false;
    if (maxParticipants != null && currentParticipants >= maxParticipants!) {
      return false;
    }
    return true;
  }

  /// Check if user has booked this event
  bool get isBooked => status?.isBooked == true;

  /// Check if user has attended this event
  bool get hasAttended => status?.hasAttended == true;

  /// Duration of the event
  Duration get duration => endTime.difference(startTime);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.location == location &&
        other.type == type &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      startTime,
      endTime,
      location,
      type,
      status,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, title: $title, description: $description, startTime: $startTime, endTime: $endTime, location: $location, imageUrl: $imageUrl, type: $type, isRegistrationRequired: $isRegistrationRequired, maxParticipants: $maxParticipants, currentParticipants: $currentParticipants, status: $status, bookingClosesAt: $bookingClosesAt)';
  }
}

/// Types of events
enum EventType {
  presentation,
  workshop,
  networking,
  panel,
  careerFair,
  social;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case EventType.presentation:
        return 'Presentation';
      case EventType.workshop:
        return 'Workshop';
      case EventType.networking:
        return 'Networking';
      case EventType.panel:
        return 'Panel Discussion';
      case EventType.careerFair:
        return 'Career Fair';
      case EventType.social:
        return 'Social Event';
    }
  }
}
