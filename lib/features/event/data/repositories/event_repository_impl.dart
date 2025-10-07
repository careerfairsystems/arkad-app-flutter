import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
import '../../domain/entities/ticket_verification_result.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_remote_data_source.dart';
import '../mappers/event_attendee_mapper.dart';
import '../mappers/event_mapper.dart';
import '../mappers/ticket_verification_mapper.dart';

/// Implementation of event repository
class EventRepositoryImpl extends BaseRepository implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;
  final EventMapper _mapper;
  final EventAttendeeMapper _attendeeMapper;
  final TicketVerificationMapper _ticketMapper;

  EventRepositoryImpl({
    required EventRemoteDataSource remoteDataSource,
    required EventMapper mapper,
    required EventAttendeeMapper attendeeMapper,
    required TicketVerificationMapper ticketMapper,
  }) : _remoteDataSource = remoteDataSource,
       _mapper = mapper,
       _attendeeMapper = attendeeMapper,
       _ticketMapper = ticketMapper;

  @override
  Future<Result<List<Event>>> getEvents() async {
    return executeOperation(() async {
      // Fetch from remote
      final eventSchemas = await _remoteDataSource.getEvents();
      print("Got ${eventSchemas} events from remote");

      // Convert to domain entities
      // Note: API doesn't provide IDs, so we'll use index as ID for now
      final events = eventSchemas.asMap().entries.map((entry) {
        return _mapper.fromApiSchema(entry.value);
      }).toList();

      return events;
    }, 'get events');
  }

  @override
  Future<Result<Event>> getEventById(int id) async {
    return executeOperation(() async {
      // Fetch from remote
      final eventSchema = await _remoteDataSource.getEventById(id);

      // Convert to domain entity
      final event = _mapper.fromApiSchema(eventSchema);

      return event;
    }, 'get event by id');
  }

  @override
  Future<Result<List<Event>>> getEventsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    return executeOperation(() async {
      // Get all events first
      final allEventsResult = await getEvents();

      return allEventsResult.when(
        success: (events) {
          // Filter events by date range - include any overlapping events
          final filteredEvents = events.where((event) {
            return event.endTime.isAfter(start) &&
                event.startTime.isBefore(end);
          }).toList();
          return filteredEvents;
        },
        failure: (error) => throw Exception(error.userMessage),
      );
    }, 'get events by date range');
  }

  @override
  Future<Result<void>> registerForEvent(int eventId) async {
    return executeOperation(() async {
      // Book the event
      await _remoteDataSource.bookEvent(eventId);
    }, 'register for event');
  }

  @override
  Future<Result<void>> unregisterFromEvent(int eventId) async {
    return executeOperation(() async {
      // Unbook the event
      await _remoteDataSource.unbookEvent(eventId);
    }, 'unregister from event');
  }

  @override
  Future<Result<List<Event>>> getBookedEvents() async {
    return executeOperation(() async {
      // Get all events and filter by booked status
      final allEventsResult = await getEvents();

      return allEventsResult.when(
        success: (events) {
          // Filter events that are booked or have tickets used
          final bookedEvents = events.where((event) {
            return event.status?.isBooked == true;
          }).toList();
          return bookedEvents;
        },
        failure: (error) => throw Exception(error.userMessage),
      );
    }, 'get booked events');
  }

  @override
  Future<Result<void>> refreshEvents() async {
    return executeOperation(() async {
      // Force refresh from remote
      await getEvents();
    }, 'refresh events');
  }

  @override
  Future<Result<String>> getEventTicket(int eventId) async {
    return executeOperation(() async {
      return await _remoteDataSource.getEventTicket(eventId);
    }, 'get event ticket');
  }

  @override
  Future<Result<List<EventAttendee>>> getEventAttendees(int eventId) async {
    return executeOperation(() async {
      // Fetch attendees from remote
      final attendeeSchemas = await _remoteDataSource.getEventAttendees(
        eventId,
      );

      // Convert to domain entities
      final attendees = attendeeSchemas
          .map((schema) => _attendeeMapper.fromApiSchema(schema))
          .toList();

      return attendees;
    }, 'get event attendees');
  }

  @override
  Future<Result<TicketVerificationResult>> useTicket(
    String token,
    int eventId,
  ) async {
    print('🎫 [EventRepositoryImpl] useTicket called');
    print('   Token: $token');
    print('   Event ID: $eventId');

    return executeOperation(() async {
      try {
        final ticketSchema = await _remoteDataSource.useTicket(token, eventId);

        final result = _ticketMapper.fromSuccessfulTicketSchema(ticketSchema);

        return result;
      } on TicketAlreadyUsedException {
        // Rethrow to be handled by executeOperation's error mapping
        rethrow;
      }
    }, 'use ticket');
  }
}
