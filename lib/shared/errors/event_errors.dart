import 'package:flutter/material.dart';

import 'app_error.dart';

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
