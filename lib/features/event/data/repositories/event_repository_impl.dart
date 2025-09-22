import '../../../../shared/data/repositories/base_repository.dart';
import '../../../../shared/domain/result.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../data_sources/event_local_data_source.dart';
import '../data_sources/event_remote_data_source.dart';
import '../mappers/event_mapper.dart';

/// Implementation of event repository
class EventRepositoryImpl extends BaseRepository implements EventRepository {
  final EventRemoteDataSource _remoteDataSource;
  final EventLocalDataSource _localDataSource;
  final EventMapper _mapper;

  EventRepositoryImpl({
    required EventRemoteDataSource remoteDataSource,
    required EventLocalDataSource localDataSource,
    required EventMapper mapper,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _mapper = mapper;

  @override
  Future<Result<List<Event>>> getEvents() async {
    return executeOperation(() async {
      // Try cache first
      final cachedEvents = _localDataSource.getCachedEvents();
      if (cachedEvents != null) {
        return cachedEvents;
      }

      // Fetch from remote
      final eventSchemas = await _remoteDataSource.getEvents();

      // Convert to domain entities
      // Note: API doesn't provide IDs, so we'll use index as ID for now
      final events =
          eventSchemas.asMap().entries.map((entry) {
            return _mapper.fromApiSchema(entry.value);
          }).toList();

      // Cache the results
      _localDataSource.cacheEvents(events);

      return events;
    }, 'get events');
  }

  @override
  Future<Result<Event>> getEventById(int id) async {
    return executeOperation(() async {
      // Try cache first
      final cachedEvent = _localDataSource.getCachedEventById(id);
      if (cachedEvent != null) {
        return cachedEvent;
      }

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
          // Filter events by date range
          final filteredEvents =
              events.where((event) {
                return event.startTime.isAfter(start) &&
                    event.endTime.isBefore(end);
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

      // Clear cache to force refresh next time
      _localDataSource.clearCache();
    }, 'register for event');
  }

  @override
  Future<Result<void>> unregisterFromEvent(int eventId) async {
    return executeOperation(() async {
      // Unbook the event
      await _remoteDataSource.unbookEvent(eventId);

      // Clear cache to force refresh next time
      _localDataSource.clearCache();
    }, 'unregister from event');
  }

  @override
  Future<Result<List<Event>>> getBookedEvents() async {
    return executeOperation(() async {
      // Fetch booked events from remote
      final eventSchemas = await _remoteDataSource.getBookedEvents();

      // Convert to domain entities
      // Note: API doesn't provide IDs, so we'll use index as ID for now
      final events =
          eventSchemas.asMap().entries.map((entry) {
            return _mapper.fromApiSchema(entry.value);
          }).toList();

      return events;
    }, 'get booked events');
  }

  @override
  Future<Result<void>> refreshEvents() async {
    return executeOperation(() async {
      // Clear cache
      _localDataSource.clearCache();

      // Force refresh from remote
      await getEvents();
    }, 'refresh events');
  }

  @override
  Future<Result<bool>> isEventBooked(int eventId) async {
    return executeOperation(() async {
      return await _remoteDataSource.isEventBooked(eventId);
    }, 'check if event is booked');
  }

  @override
  Future<Result<String>> getEventTicket(int eventId) async {
    return executeOperation(() async {
      return await _remoteDataSource.getEventTicket(eventId);
    }, 'get event ticket');
  }
}
