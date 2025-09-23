import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';

import '../../../../shared/domain/result.dart';
import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_attendee.dart';
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
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.getEventById(id);

    result.when(
      success: (event) {
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
        _setLoading(false);
        // Optionally refresh events to get updated participant count
        loadEvents();
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
        _setLoading(false);
        // Optionally refresh events to get updated participant count
        loadEvents();
      },
      failure: (error) {
        _setError(error);
        _setLoading(false);
      },
    );

    return result.isSuccess;
  }

  /// Check if an event is booked by the current user
  Future<bool?> isEventBooked(int eventId) async {
    _clearError();

    final result = await _eventRepository.isEventBooked(eventId);

    return result.when(
      success: (isBooked) => isBooked,
      failure: (error) {
        _setError(error);
        return null;
      },
    );
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
  Future<Result<TicketSchema>> useTicket(String token, int eventId) async {
    _setLoading(true);
    _clearError();

    final result = await _eventRepository.useTicket(token, eventId);

    result.when(
      success: (_) {
        _setLoading(false);
      },
      failure: (error) {
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

  void _clearError() {
    _error = null;
  }
}
