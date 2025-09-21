import 'package:flutter/material.dart';

import '../../../../shared/errors/app_error.dart';
import '../../domain/entities/event.dart';
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
