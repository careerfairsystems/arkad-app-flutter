import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';

/// Exception thrown when a ticket has already been used or user doesn't have a ticket
class TicketAlreadyUsedException implements Exception {
  final String token;
  final int eventId;

  const TicketAlreadyUsedException(this.token, this.eventId);

  @override
  String toString() => 'TicketAlreadyUsedException: Ticket $token for event $eventId has already been used or does not exist';
}

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

  /// Get attendees for a specific event (staff only)
  Future<List<EventUserInformation>> getEventAttendees(int eventId) async {
    try {
      final response = await _api.getEventsApi().eventBookingApiGetUsersAttendingEvent(
        eventId: eventId,
      );

      if (response.isSuccess) {
        return response.data?.toList() ?? <EventUserInformation>[];
      } else {
        response.logResponse('getEventAttendees');
        throw Exception(
          'Failed to get attendees for event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getEventAttendees',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      await Sentry.captureException(e);
      throw Exception('Failed to get attendees for event $eventId: $e');
    }
  }

  /// Use/verify a ticket (staff only)
  /// Returns either TicketSchema for successful verification or throws specific exceptions
  Future<TicketSchema> useTicket(String token, int eventId) async {
    try {
      final useTicketSchema = UseTicketSchema((b) => b
        ..uuid = token
        ..eventId = eventId);

      final response = await _api.getEventsApi().eventBookingApiVerifyTicket(
        useTicketSchema: useTicketSchema,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('useTicket');
        if (response.data == null) {
          throw Exception('Failed to use ticket');
        }
        throw Exception(
          'Failed to use ticket: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      // Check for 404 error indicating ticket already used or no ticket
      if (e.response?.statusCode == 404) {
        throw TicketAlreadyUsedException(token, eventId);
      }

      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'useTicket',
        additionalContext: {'eventId': eventId, 'token': token},
      );
      throw exception;
    } catch (e) {
      if (e is TicketAlreadyUsedException) {
        rethrow;
      }
      await Sentry.captureException(e);
      throw Exception('Failed to use ticket: $e');
    }
  }
}
