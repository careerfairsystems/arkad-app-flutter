import 'package:arkad_api/arkad_api.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Remote data source for event operations
class EventRemoteDataSource {
  final ArkadApi _api;

  EventRemoteDataSource(this._api);

  /// Get all events from the API
  Future<List<EventSchema>> getEvents() async {
    try {
      final response = await _api
          .getEventsApi()
          .eventBookingApiGetEvents();
      return response.data?.toList() ?? <EventSchema>[];
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get events: $e');
    }
  }

  /// Get a specific event by ID
  Future<EventSchema> getEventById(int eventId) async {
    try {
      final response = await _api
          .getEventsApi()
          .eventBookingApiGetEvent(eventId: eventId);

      if (response.data == null) {
        throw Exception('Event not found');
      }

      return response.data!;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get event $eventId: $e');
    }
  }

  /// Get booked events for the current user
  Future<List<EventSchema>> getBookedEvents() async {
    try {
      final response = await _api
          .getEventsApi()
          .eventBookingApiGetBookedEvents();
      return response.data?.toList() ?? <EventSchema>[];
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get booked events: $e');
    }
  }

  /// Book/register for an event
  Future<EventSchema> bookEvent(int eventId) async {
    try {
      final response = await _api
          .getEventsApi()
          .eventBookingApiBookEvent(eventId: eventId);

      if (response.data == null) {
        throw Exception('Failed to book event');
      }

      return response.data!;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to book event $eventId: $e');
    }
  }

  /// Unbook/unregister from an event
  Future<EventSchema> unbookEvent(int eventId) async {
    try {
      final response = await _api
          .getEventsApi()
          .eventBookingApiUnbookEvent(eventId: eventId);

      if (response.data == null) {
        throw Exception('Failed to unbook event');
      }

      return response.data!;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to unbook event $eventId: $e');
    }
  }
}