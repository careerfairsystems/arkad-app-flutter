import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/services/student_session_status_service.dart';

/// Presentation layer mapper for StudentSessionStatusService
/// Maps domain status information to UI-specific types (Colors, Icons, etc.)
class StudentSessionStatusMapper {
  const StudentSessionStatusMapper._();

  static const StudentSessionStatusMapper instance =
      StudentSessionStatusMapper._();

  /// Map domain status info to UI status info with colors and icons
  StudentSessionUIStatusInfo mapStatusInfo(
    StudentSessionStatusInfo domainInfo,
  ) {
    return StudentSessionUIStatusInfo(
      badgeText: domainInfo.badgeText,
      badgeColor: domainInfo.badgeText != null
          ? _mapBadgeColor(domainInfo.badgeText!)
          : null,
      canApply: domainInfo.canApply,
      canBook: domainInfo.canBook,
      hasBooking: domainInfo.hasBooking,
    );
  }

  /// Map domain action info to UI action info with colors and icons
  StudentSessionUIActionInfo mapActionInfo(ActionButtonInfo domainInfo) {
    return StudentSessionUIActionInfo(
      text: domainInfo.text,
      icon: _mapActionIcon(domainInfo.action),
      color: _mapActionColor(domainInfo.action, domainInfo.isEnabled),
      action: domainInfo.action,
      isEnabled: domainInfo.isEnabled,
    );
  }

  // Private mapping methods

  Color _mapBadgeColor(String badgeText) {
    switch (badgeText.toLowerCase()) {
      case 'pending':
      case 'under review':
        return ArkadColors.arkadOrange;
      case 'accepted!':
      case 'you were accepted!':
        return ArkadColors.arkadGreen;
      case 'rejected':
      case 'not selected':
        return ArkadColors.lightRed;
      default:
        return ArkadColors.arkadTurkos;
    }
  }

  IconData _mapActionIcon(ActionType actionType) {
    switch (actionType) {
      case ActionType.apply:
        return Icons.send_rounded;
      case ActionType.bookTimeslot:
        return Icons.schedule_rounded;
      case ActionType.manageBooking:
        return Icons.edit_calendar_rounded;
      case ActionType.none:
        return Icons.info_outline_rounded;
    }
  }

  Color _mapActionColor(ActionType actionType, bool isEnabled) {
    if (!isEnabled) {
      return ArkadColors.gray;
    }

    switch (actionType) {
      case ActionType.apply:
      case ActionType.bookTimeslot:
      case ActionType.manageBooking:
        return ArkadColors.arkadTurkos;
      case ActionType.none:
        return ArkadColors.gray;
    }
  }
}

/// UI-specific status information with Flutter types
class StudentSessionUIStatusInfo {
  const StudentSessionUIStatusInfo({
    this.badgeText,
    this.badgeColor,
    required this.canApply,
    required this.canBook,
    required this.hasBooking,
  });

  /// Text for status badge (null if no badge should be shown)
  final String? badgeText;

  /// Color for status badge (null if no badge should be shown)
  final Color? badgeColor;

  /// Whether the user can apply to this session
  final bool canApply;

  /// Whether the user can book a timeslot for this session
  final bool canBook;

  /// Whether the user has a booking for this session
  final bool hasBooking;
}

/// UI-specific action button information with Flutter types
class StudentSessionUIActionInfo {
  const StudentSessionUIActionInfo({
    required this.text,
    required this.icon,
    required this.color,
    required this.action,
    required this.isEnabled,
  });

  /// Text to display on the button
  final String text;

  /// Icon to display on the button
  final IconData icon;

  /// Color of the button
  final Color color;

  /// Type of action this button performs
  final ActionType action;

  /// Whether the button is enabled
  final bool isEnabled;
}
