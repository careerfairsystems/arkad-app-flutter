import 'package:flutter/material.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
import '../../domain/entities/event_status.dart';
import '../../domain/entities/ticket_verification_result.dart';
import '../../domain/repositories/event_repository.dart';

/// ViewModel for managing event state and operations
class EventViewModel extends ChangeNotifier {
  final EventRepository _eventRepository;

  EventViewModel({required EventRepository eventRepository})
    : _eventRepository = eventRepository;

  // State
  bool _isLoading = false;
  AppError? _error;
  List<Event> _events = [];
  List<Event> _bookedEvents = [];
  Event? _selectedEvent;

  // Getters
  bool get isLoading => _isLoading;
  AppError? get error => _error;
  List<Event> get events => _events;
  List<Event> get bookedEvents => _bookedEvents;
  Event? get selectedEvent => _selectedEvent;

  /// Load events
  Future<bool> loadEvents() async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEvents();

    result.when(
      success: (events) {
        _events = events;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Get event by ID
  Future<bool> getEventById(int id) async {
    print('🔍 [EventViewModel] getEventById called with id=$id');
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventById(id);
    print('🔍 [EventViewModel] Repository result: success=${result.isSuccess}');

    result.when(
      success: (event) {
        print('   ✅ Success: Got event "${event.title}" with ID=${event.id}');
        _selectedEvent = event;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Register for an event
  Future<bool> registerForEvent(int eventId) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.registerForEvent(eventId);

    result.when(
      success: (_) {
        // Update the selected event status to booked
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = _selectedEvent!.copyWith(status: EventStatus.booked);
        }

        // Update the event in the events list
        _events = _events.map((event) {
          if (event.id == eventId) {
            return event.copyWith(status: EventStatus.booked);
          }
          return event;
        }).toList();

        // Add the event to booked events list if not already there
        final eventToAdd = _events.firstWhere((event) => event.id == eventId);
        if (!_bookedEvents.any((event) => event.id == eventId)) {
          _bookedEvents.add(eventToAdd.copyWith(status: EventStatus.booked));
        }

        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Unregister from an event
  Future<bool> unregisterFromEvent(int eventId) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.unregisterFromEvent(eventId);

    result.when(
      success: (_) {
        // Update the selected event status to not booked
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = _selectedEvent!.copyWith(
            status: EventStatus.notBooked,
          );
        }

        // Update the event in the events list
        _events = _events.map((event) {
          if (event.id == eventId) {
            return event.copyWith(status: EventStatus.notBooked);
          }
          return event;
        }).toList();

        // Update the event in the booked events list (remove it)
        _bookedEvents = _bookedEvents
            .where((event) => event.id != eventId)
            .toList();

        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Get event ticket for a specific event
  Future<String?> getEventTicket(int eventId) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventTicket(eventId);

    String? ticket;
    result.when(
      success: (ticketUuid) {
        ticket = ticketUuid;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
        ticket = null;
      },
    );

    return ticket;
  }

  /// Load booked events for the current user
  Future<bool> loadBookedEvents() async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getBookedEvents();

    result.when(
      success: (events) {
        _bookedEvents = events;
        _setLoading(false);
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Refresh events
  Future<void> refreshEvents() async {
    await loadEvents();
  }

  /// Refresh booked events
  Future<void> refreshBookedEvents() async {
    await loadBookedEvents();
  }

  /// Get attendees for an event (staff only)
  Future<Result<List<EventAttendee>>> getEventAttendees(int eventId) async {
    return await _eventRepository.getEventAttendees(eventId);
  }

  /// Use/verify a ticket (staff only)
  Future<Result<TicketVerificationResult>> useTicket(
    String token,
    int eventId,
  ) async {
    print('🎫 [EventViewModel] useTicket called');
    print('   Token: $token');
    print('   Event ID: $eventId');

    _setLoading(true);
    _clearError();

    print('🎫 [EventViewModel] Calling repository...');
    final result = await _eventRepository.useTicket(token, eventId);

    print('🎫 [EventViewModel] Repository result received');
    result.when(
      success: (verification) {
        print('🎫 [EventViewModel] Success result:');
        print('   Status: ${verification.status}');
        print('   UUID: ${verification.uuid}');
        print('   Event ID: ${verification.eventId}');
        print('   User Info: ${verification.userInfo?.toString()}');
        _setLoading(false);
      },
      failure: (error) {
        print('🎫 [EventViewModel] Failure result:');
        print('   Error type: ${error.runtimeType}');
        print('   Error message: ${error.userMessage}');
        _setError(error);
        _setLoading(false);
      },
    );

    return result;
  }

  // State management helpers
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(AppError? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
