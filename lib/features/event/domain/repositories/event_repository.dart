import 'package:arkad_api/arkad_api.dart';

import '../../../../shared/domain/result.dart';
import '../entities/event.dart';
import '../entities/event_attendee.dart';
import '../entities/ticket_verification_result.dart';

/// Repository interface for event operations
abstract class EventRepository {
  /// Get all events
  Future<Result<List<Event>>> getEvents();

  /// Get event by ID
  Future<Result<Event>> getEventById(int id);

  /// Get events by date range
  Future<Result<List<Event>>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  );

  /// Register for an event
  Future<Result<void>> registerForEvent(int eventId);

  /// Unregister from an event
  Future<Result<void>> unregisterFromEvent(int eventId);

  /// Get booked events for the current user
  Future<Result<List<Event>>> getBookedEvents();

  /// Get event ticket (Should be rendered as QR code)
  Future<Result<String>> getEventTicket(int eventId);

  /// Check if an event is booked by the current user
  Future<Result<bool>> isEventBooked(int eventId);

  /// Refresh cached event data
  Future<Result<void>> refreshEvents();

  /// Get attendees for an event (staff only)
  Future<Result<List<EventAttendee>>> getEventAttendees(int eventId);

  /// Use/verify a ticket (staff only)
  Future<Result<TicketVerificationResult>> useTicket(String token, int eventId);
}
