import '../../../../shared/infrastructure/services/timezone_service.dart';
import '../services/event_timeline_validation_service.dart';
import 'event_status.dart';

/// Domain entity representing an event
/// All DateTime fields are stored in Stockholm timezone for consistency
class Event {
  final int id;
  final String title;
  final String description;
  final DateTime? releaseTime;
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
    this.releaseTime,
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
    DateTime? releaseTime,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    String? imageUrl,
    EventType? type,
    bool? isRegistrationRequired,
    int? maxParticipants,
    int? currentParticipants,
    EventStatus? status,
    DateTime? bookingClosesAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      releaseTime: releaseTime ?? this.releaseTime,
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
      bookingClosesAt: bookingClosesAt ?? this.bookingClosesAt,
    );
  }

  /// Check if event is visible (released)
  /// Uses centralized timeline validation service with Stockholm timezone
  bool get isVisible =>
      EventTimelineValidationService.instance.isEventVisible(this);

  /// Check if booking period is active
  /// Uses centralized timeline validation service with Stockholm timezone
  bool get isBookingPeriodActive =>
      EventTimelineValidationService.instance.isBookingPeriodActive(this);

  /// Check if booking deadline has passed
  /// Uses centralized timeline validation service with Stockholm timezone
  bool get bookingDeadlineClosed =>
      EventTimelineValidationService.instance.hasBookingDeadlinePassed(this);

  /// Check if event has started
  /// Uses Stockholm timezone via TimezoneService
  bool get hasStarted => TimezoneService.isInPast(startTime);

  /// Check if event has ended
  /// Uses Stockholm timezone via TimezoneService
  bool get hasEnded => TimezoneService.isInPast(endTime);

  /// Check if event is currently happening
  bool get isOngoing => hasStarted && !hasEnded;

  /// Check if registration is still available
  /// Uses centralized timeline validation service with Stockholm timezone
  bool get canRegister =>
      EventTimelineValidationService.instance.canRegister(this);

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
