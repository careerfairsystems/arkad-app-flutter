import '../../../../shared/infrastructure/services/timezone_service.dart';
import '../entities/event.dart';

/// Centralized service for timeline validation logic across event features
/// Provides consistent validation rules for event visibility and booking periods:
/// 1. Visibility Period: Events become visible after releaseTime
/// 2. Booking Period: Events can be booked/unbooked between releaseTime and bookingClosesAt
class EventTimelineValidationService {
  const EventTimelineValidationService._();

  static const EventTimelineValidationService instance =
      EventTimelineValidationService._();

  /// Check if event is visible to users
  /// Returns true if event should be displayed (after releaseTime or no releaseTime set)
  bool isEventVisible(Event event, {DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    // If no release time is set, event is always visible
    if (event.releaseTime == null) return true;

    // Event becomes visible after releaseTime
    return currentTime.isAfter(event.releaseTime!) ||
        currentTime.isAtSameMomentAs(event.releaseTime!);
  }

  /// Check if booking period is currently active for an event
  /// Returns true if users can book or unbook the event now
  /// Booking is possible between releaseTime and bookingClosesAt
  bool isBookingPeriodActive(Event event, {DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    // Check if event is released (visible)
    if (!isEventVisible(event, now: currentTime)) return false;

    // Check if booking hasn't frozen yet
    return currentTime.isBefore(event.bookingClosesAt) ||
        currentTime.isAtSameMomentAs(event.bookingClosesAt);
  }

  /// Check if booking deadline has passed
  /// Returns true if bookingClosesAt is in the past
  bool hasBookingDeadlinePassed(Event event, {DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();
    return currentTime.isAfter(event.bookingClosesAt);
  }

  /// Check if user can register for an event
  /// Combines multiple conditions: visibility, booking period, capacity, and current status
  bool canRegister(Event event, {DateTime? now}) {
    // Event must be visible
    if (!isEventVisible(event, now: now)) return false;

    // Must require registration
    if (!event.isRegistrationRequired) return false;

    // Booking period must be active
    if (!isBookingPeriodActive(event, now: now)) return false;

    // Cannot register if already booked
    if (event.isBooked) return false;

    // Check capacity limits
    if (event.maxParticipants != null &&
        event.currentParticipants >= event.maxParticipants!) {
      return false;
    }

    return true;
  }
}
