import '../../../../shared/domain/result.dart';
import '../entities/event.dart';

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

  /// Refresh cached event data
  Future<Result<void>> refreshEvents();
}
