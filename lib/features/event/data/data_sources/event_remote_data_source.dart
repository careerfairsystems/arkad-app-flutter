import 'package:arkad/shared/errors/app_error.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../api/extensions.dart';
import '../../../../shared/data/api_error_handler.dart';

/// Exception thrown when a ticket has already been used or user doesn't have a ticket
class TicketAlreadyUsedException extends AppError {
  final String token;
  final int eventId;

  const TicketAlreadyUsedException(this.token, this.eventId)
    : super(
        userMessage: 'Ticket has already been used or does not exist',
        technicalDetails:
            'Ticket $token for event $eventId has already been used or does not exist',
        severity: ErrorSeverity.warning,
      );

  @override
  String toString() =>
      'TicketAlreadyUsedException: Ticket $token for event $eventId has already been used or does not exist';
}

/// Exception thrown when an event is at full capacity
class EventFullException extends AppError {
  final int eventId;

  const EventFullException(this.eventId, String message)
      : super(
          userMessage: 'This event is full',
          technicalDetails: 'Event $eventId is at full capacity: $message',
          severity: ErrorSeverity.warning,
        );

  @override
  String toString() => 'EventFullException: Event $eventId is full';
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
    print(
      '🔍 [EventRemoteDataSource] Fetching event from API: eventId=$eventId',
    );
    print('   API endpoint: GET /api/events/$eventId/');

    try {
      final response = await _api.getEventsApi().eventBookingApiGetEvent(
        eventId: eventId,
      );

      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        response.logResponse('getEventById');
        if (response.data == null) {
          if (kDebugMode) {
            debugPrint('   Event not found (404)');
          }
          throw Exception('Event not found');
        }
        throw Exception(
          'Failed to get event $eventId: ${response.detailedError}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint('   DioException: ${e.response?.statusCode} - ${e.message}');
      }
      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'getEventById',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('   Exception: $e');
      }
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
      // Check for 409 status code (event full)
      if (e.response?.statusCode == 409) {
        final errorMessage = ApiErrorHandler.extractErrorMessage(
          e.response?.data,
        );
        throw EventFullException(eventId, errorMessage);
      }

      final exception = await ApiErrorHandler.handleDioException(
        e,
        operationName: 'bookEvent',
        additionalContext: {'eventId': eventId},
      );
      throw exception;
    } catch (e) {
      if (e is EventFullException || e is AppError) {
        rethrow;
      }
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
      final response = await _api
          .getEventsApi()
          .eventBookingApiGetUsersAttendingEvent(eventId: eventId);

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
    print('🎫 [EventRemoteDataSource] useTicket called');
    print('   Token: $token');
    print('   Event ID: $eventId');

    try {
      final useTicketSchema = UseTicketSchema(
        (b) => b
          ..uuid = token
          ..eventId = eventId,
      );

      print('🎫 [EventRemoteDataSource] Sending API request...');
      final response = await _api.getEventsApi().eventBookingApiVerifyTicket(
        useTicketSchema: useTicketSchema,
      );

      print('🎫 [EventRemoteDataSource] API response received');
      print('   Status code: ${response.statusCode}');
      print('   Success: ${response.isSuccess}');
      print('   Has data: ${response.data != null}');

      if (response.data != null) {
        print('🎫 [EventRemoteDataSource] Response data:');
        print('   UUID: ${response.data!.uuid}');
        print('   Event ID: ${response.data!.eventId}');
        print('   Used: ${response.data!.used}');
        print('   User ID: ${response.data!.user.id}');
        print(
          '   User Name: ${response.data!.user.firstName} ${response.data!.user.lastName}',
        );

        // Log to Sentry for tracking
        Sentry.logger.info(
          'Ticket verification response received',
          attributes: {
            'event_id': SentryLogAttribute.int(eventId),
            'has_data': SentryLogAttribute.bool(response.data != null),
            'status_code': SentryLogAttribute.int(response.statusCode ?? 0),
            'used': SentryLogAttribute.bool(response.data!.used),
          },
        );
      }

      if (response.isSuccess && response.data != null) {
        print('   ✅ Ticket verification successful');
        return response.data!;
      } else {
        response.logResponse('useTicket');
        if (response.data == null) {
          print('   ❌ No data in response');
          throw Exception('Failed to use ticket');
        }
        print('   ❌ Response not successful: ${response.detailedError}');
        throw Exception('Failed to use ticket: ${response.detailedError}');
      }
    } on DioException catch (e) {
      print('🎫 [EventRemoteDataSource] DioException caught');
      print('   Status code: ${e.response?.statusCode}');
      print('   Response data: ${e.response?.data}');
      print('   Message: ${e.message}');

      // Check for 404 error indicating ticket already used or no ticket
      if (e.response?.statusCode == 404) {
        print('   ❌ 404 - Ticket already used or does not exist');
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
      print('🎫 [EventRemoteDataSource] Unexpected exception: $e');
      await Sentry.captureException(e);
      throw Exception('Failed to use ticket: $e');
    }
  }
}
