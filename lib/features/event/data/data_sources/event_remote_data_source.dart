import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';

/// Remote data source for event operations
class EventRemoteDataSource {
  final ArkadApi _api;

  EventRemoteDataSource(this._api);

  /// Get all events from the API
  Future<List<EventSchema>> getEvents() async {
    try {
      final response = await _api.getEventsApi().eventBookingApiGetEvents();

      if (response.isSuccess) {
        return response.data?.toList() ?? <EventSchema>[];
      } else {
        response.logResponse('getEvents');
        throw Exception('Failed to get events: ${response.detailedError}');
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getEvents',
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get events: $e');
    }
  }

  /// Get a specific event by ID
  Future<EventSchema> getEventById(int eventId) async {
    try {
      final response = await _api.getEventsApi().eventBookingApiGetEvent(
        eventId: eventId,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('getEventById');
        if (response.data == null) {
          throw Exception('Event not found');
        }
        throw Exception(
          'Failed to get event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getEventById',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get event $eventId: $e');
    }
  }

  /// Get booked events for the current user
  Future<List<EventSchema>> getBookedEvents() async {
    try {
      final response =
          await _api.getEventsApi().eventBookingApiGetBookedEvents();

      if (response.isSuccess) {
        return response.data?.toList() ?? <EventSchema>[];
      } else {
        response.logResponse('getBookedEvents');
        throw Exception(
          'Failed to get booked events: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getBookedEvents',
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get booked events: $e');
    }
  }

  /// Book/register for an event
  Future<EventSchema> bookEvent(int eventId) async {
    try {
      final response = await _api.getEventsApi().eventBookingApiBookEvent(
        eventId: eventId,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('bookEvent');
        if (response.data == null) {
          throw Exception('Failed to book event');
        }
        throw Exception(
          'Failed to book event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'bookEvent',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to book event $eventId: $e');
    }
  }

  /// Unbook/unregister from an event
  Future<EventSchema> unbookEvent(int eventId) async {
    try {
      final response = await _api.getEventsApi().eventBookingApiUnbookEvent(
        eventId: eventId,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('unbookEvent');
        if (response.data == null) {
          throw Exception('Failed to unbook event');
        }
        throw Exception(
          'Failed to unbook event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'unbookEvent',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to unbook event $eventId: $e');
    }
  }

  /// Check if an event is booked by the current user
  Future<bool> isEventBooked(int eventId) async {
    try {
      final bookedEvents = await getBookedEvents();
      return bookedEvents.any((event) => event.id == eventId);
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to check if event $eventId is booked: $e');
    }
  }

  /// Get event ticket for a specific event
  Future<String> getEventTicket(int eventId) async {
    try {
      final response = await _api.getEventsApi().eventBookingApiGetEventTicket(
        eventId: eventId,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!.uuid;
      } else {
        response.logResponse('getEventTicket');
        if (response.data == null) {
          throw Exception('No ticket found for event');
        }
        throw Exception(
          'Failed to get ticket for event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getEventTicket',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get ticket for event $eventId: $e');
    }
  }
}
