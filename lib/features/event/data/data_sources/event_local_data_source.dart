import '../../domain/entities/event.dart';

/// Local data source for caching event data
class EventLocalDataSource {
  // For now, this is a simple in-memory cache
  // In the future, this could use a database like Hive or SQLite

  List<Event>? _cachedEvents;
  List<Event>? _cachedBookedEvents;

  /// Cache events
  void cacheEvents(List<Event> events) {
    _cachedEvents = events;
  }

  /// Get cached events
  List<Event>? getCachedEvents() {
    return _cachedEvents;
  }

  /// Cache booked events
  void cacheBookedEvents(List<Event> bookedEvents) {
    _cachedBookedEvents = bookedEvents;
  }

  /// Get cached booked events
  List<Event>? getCachedBookedEvents() {
    return _cachedBookedEvents;
  }

  /// Get cached event by ID
  Event? getCachedEventById(int id) {
    return _cachedEvents?.where((event) => event.id == id).firstOrNull;
  }

  /// Clear all cached data
  void clearCache() {
    _cachedEvents = null;
    _cachedBookedEvents = null;
  }

  /// Check if events cache is valid (for now, always false - no expiry logic)
  bool get isEventsCacheValid => _cachedEvents != null;

  /// Check if booked events cache is valid
  bool get isBookedEventsCacheValid => _cachedBookedEvents != null;
}
