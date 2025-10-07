import 'package:flutter/material.dart';

import 'app_error.dart';

/// Exception thrown when a ticket has already been used or user doesn't have a ticket
class TicketAlreadyUsedException extends AppError {
  const TicketAlreadyUsedException(this.token, this.eventId)
    : super(
        userMessage: 'Ticket has already been used or does not exist',
        technicalDetails:
            'Ticket $token for event $eventId has already been used or does not exist',
        severity: ErrorSeverity.warning,
      );

  final String token;
  final int eventId;

  @override
  String toString() =>
      'TicketAlreadyUsedException: Ticket $token for event $eventId has already been used or does not exist';
}

/// Exception thrown when an event is at full capacity
class EventFullException extends AppError {
  const EventFullException(this.eventId, String message)
    : super(
        userMessage: 'This event is full',
        technicalDetails: 'Event $eventId is at full capacity: $message',
        severity: ErrorSeverity.warning,
      );

  final int eventId;

  @override
  String toString() => 'EventFullException: Event $eventId is full';
}

/// Event registration error for when event is at full capacity
class EventFullError extends AppError {
  const EventFullError(this.eventTitle, {String? details})
    : super(
        userMessage: "This event is fully booked",
        severity: ErrorSeverity.warning,
        technicalDetails: details,
      );

  final String eventTitle;
}

/// Event registration generic error
class EventRegistrationError extends AppError {
  const EventRegistrationError(String message, {String? details})
    : super(
        userMessage: message,
        severity: ErrorSeverity.error,
        technicalDetails: details,
      );
}

/// Recovery actions for event errors
class EventRecoveryActions {
  /// Create recovery actions for event full errors
  static List<RecoveryAction> forEventFull(
    EventFullError error,
    BuildContext? context,
    VoidCallback? onBrowseEvents,
  ) {
    if (context == null) return [];

    return [
      if (onBrowseEvents != null)
        RecoveryAction(
          label: 'Browse Other Events',
          action: onBrowseEvents,
          icon: Icons.event,
          isPrimary: true,
        ),
      RecoveryAction(
        label: 'Go Back',
        action: () => Navigator.of(context).pop(),
        icon: Icons.arrow_back,
      ),
    ];
  }
}
