import 'package:collection/collection.dart';

import '../../../../shared/infrastructure/services/timezone_service.dart';
import 'field_configuration.dart';

/// Session type enum - distinguishes regular sessions from company events
enum StudentSessionType {
  regular('regular'),
  companyEvent('company_event');

  const StudentSessionType(this.value);

  final String value;

  /// Create from API string value
  static StudentSessionType fromValue(String? value) {
    if (value == null) return StudentSessionType.regular;
    for (final type in StudentSessionType.values) {
      if (type.value == value) return type;
    }
    return StudentSessionType.regular; // Default for unknown values
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case StudentSessionType.regular:
        return 'Student Session';
      case StudentSessionType.companyEvent:
        return 'Company Visit';
    }
  }
}

/// Domain entity representing a student session for a company
/// Maps from StudentSessionNormalUserSchema in API
class StudentSession {
  const StudentSession({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.isAvailable,
    required this.name,
    this.sessionType = StudentSessionType.regular,
    this.bookingCloseTime,
    this.bookingOpenTime,
    this.userStatus,
    this.logoUrl,
    this.description,
    this.disclaimer,
    this.fieldConfigurations = const [],
    this.location,
    this.companyEventAt,
  });

  /// Unique identifier for this student session
  final int id;

  /// ID of the company offering this session
  final int companyId;

  /// Name of the company (for display purposes)
  final String companyName;

  final String name;

  /// Whether this session is available for applications/booking
  final bool isAvailable;

  /// Type of session (regular or company event)
  final StudentSessionType sessionType;

  /// Location of the session or event (optional)
  final String? location;

  /// Date/time when company event occurs (only for company events)
  final DateTime? companyEventAt;

  /// When APPLICATION period closes for this session (null if no application period)
  /// Note: Despite the "booking" name, this field controls when users can APPLY to the session
  final DateTime? bookingCloseTime;

  /// When APPLICATION period opens for this session (null if no application period)
  /// Note: Despite the "booking" name, this field controls when users can APPLY to the session
  final DateTime? bookingOpenTime;

  /// Current user's application status for this session
  final StudentSessionStatus? userStatus;

  /// Company logo URL for display
  final String? logoUrl;

  /// Session description (optional)
  final String? description;

  /// Session disclaimer text (optional)
  final String? disclaimer;

  /// Field configurations for dynamic form rendering
  final List<FieldConfiguration> fieldConfigurations;

  /// Check if this is a company event
  bool get isCompanyEvent => sessionType == StudentSessionType.companyEvent;

  /// Check if this is a regular student session
  bool get isRegularSession => sessionType == StudentSessionType.regular;

  /// Check if user has applied to this session
  bool get hasApplied => userStatus != null;

  /// Check if user's application is pending
  bool get isPending => userStatus == StudentSessionStatus.pending;

  /// Check if user's application was accepted
  bool get isAccepted => userStatus == StudentSessionStatus.accepted;

  /// Check if user's application was rejected
  bool get isRejected => userStatus == StudentSessionStatus.rejected;

  /// Check if user can apply to this session (basic availability check)
  bool get canApply => isAvailable && !hasApplied;

  /// Check if user can apply to this session with timeline validation
  bool get canApplyNow => canApply && isApplicationPeriodActive();

  /// Check if user can book timeslots (must be accepted)
  /// Note: Actual booking availability depends on individual timeslot deadlines
  bool get canBook => isAccepted;

  /// Check if APPLICATION period is currently active
  /// This determines when users can submit applications to this session
  /// Uses session-level bookingOpenTime/bookingCloseTime (which are application period fields)
  bool isApplicationPeriodActive({DateTime? now}) {
    final currentTime = now ?? TimezoneService.stockholmNow();

    // If no application times are set, use basic availability
    if (bookingOpenTime == null && bookingCloseTime == null) {
      return isAvailable;
    }

    // Direct comparison since both times are in Stockholm timezone
    final isAfterOpen =
        bookingOpenTime == null ||
        currentTime.isAfter(bookingOpenTime!) ||
        currentTime.isAtSameMomentAs(bookingOpenTime!);
    final isBeforeClose =
        bookingCloseTime == null || currentTime.isBefore(bookingCloseTime!);

    return isAfterOpen && isBeforeClose && isAvailable;
  }

  /// Get field configuration for a specific field
  FieldConfiguration? getFieldConfiguration(String fieldName) {
    for (final config in fieldConfigurations) {
      if (config.fieldName == fieldName) return config;
    }
    return null;
  }

  /// Check if a field should be displayed (not hidden)
  bool isFieldVisible(String fieldName) {
    final config = getFieldConfiguration(fieldName);
    return config?.isVisible ?? true; // Default to visible if no config found
  }

  /// Check if a field is required for form submission
  bool isFieldRequired(String fieldName) {
    final config = getFieldConfiguration(fieldName);
    return config?.isRequired ?? true; // Default to required if no config found
  }

  /// Check if a field is optional (visible but not required)
  bool isFieldOptional(String fieldName) {
    final config = getFieldConfiguration(fieldName);
    return config?.isOptional ?? false;
  }

  /// Check if a field should be hidden from the form
  bool isFieldHidden(String fieldName) {
    final config = getFieldConfiguration(fieldName);
    return config?.isHidden ?? false;
  }

  /// Get the field level for a specific field
  FieldLevel getFieldLevel(String fieldName) {
    final config = getFieldConfiguration(fieldName);
    return config?.level ??
        FieldLevel.required; // Default to required if no config found
  }

  /// Create a copy with updated values
  StudentSession copyWith({
    int? id,
    int? companyId,
    String? companyName,
    bool? isAvailable,
    StudentSessionType? sessionType,
    DateTime? bookingCloseTime,
    DateTime? bookingOpenTime,
    StudentSessionStatus? userStatus,
    String? logoUrl,
    String? description,
    String? disclaimer,
    List<FieldConfiguration>? fieldConfigurations,
    String? location,
    DateTime? companyEventAt,
  }) {
    return StudentSession(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      name: name,
      isAvailable: isAvailable ?? this.isAvailable,
      sessionType: sessionType ?? this.sessionType,
      bookingCloseTime: bookingCloseTime ?? this.bookingCloseTime,
      bookingOpenTime: bookingOpenTime ?? this.bookingOpenTime,
      userStatus: userStatus ?? this.userStatus,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      disclaimer: disclaimer ?? this.disclaimer,
      fieldConfigurations: fieldConfigurations ?? this.fieldConfigurations,
      location: location ?? this.location,
      companyEventAt: companyEventAt ?? this.companyEventAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentSession &&
        other.id == id &&
        other.companyId == companyId &&
        other.companyName == companyName &&
        other.isAvailable == isAvailable &&
        other.sessionType == sessionType &&
        other.bookingCloseTime == bookingCloseTime &&
        other.bookingOpenTime == bookingOpenTime &&
        other.userStatus == userStatus &&
        other.logoUrl == logoUrl &&
        other.description == description &&
        other.disclaimer == disclaimer &&
        other.location == location &&
        other.companyEventAt == companyEventAt &&
        const ListEquality().equals(
          other.fieldConfigurations,
          fieldConfigurations,
        );
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      companyName,
      isAvailable,
      sessionType,
      bookingCloseTime,
      bookingOpenTime,
      userStatus,
      logoUrl,
      Object.hash(
        description,
        disclaimer,
        location,
        companyEventAt,
        const ListEquality().hash(fieldConfigurations),
      ),
    );
  }

  @override
  String toString() {
    return 'StudentSession(id: $id, companyId: $companyId, type: ${sessionType.value})';
  }
}

/// Status of user's student session application
/// Maps from StudentSessionNormalUserSchemaUserStatusEnum in API
enum StudentSessionStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected');

  const StudentSessionStatus(this.value);

  final String value;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case StudentSessionStatus.pending:
        return 'Pending';
      case StudentSessionStatus.accepted:
        return 'Accepted';
      case StudentSessionStatus.rejected:
        return 'Rejected';
    }
  }

  /// Create from API string value
  static StudentSessionStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in StudentSessionStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// Check if status allows timeslot booking
  bool get allowsBooking => this == StudentSessionStatus.accepted;

  /// Check if status indicates success
  bool get isPositive => this == StudentSessionStatus.accepted;

  /// Check if status indicates failure
  bool get isNegative => this == StudentSessionStatus.rejected;
}

/// Parameters for applying to a student session
/// Maps to StudentSessionApplicationSchema in API
class StudentSessionApplicationParams {
  const StudentSessionApplicationParams({
    required this.companyId,
    required this.motivationText,
    this.programme,
    this.linkedin,
    this.masterTitle,
    this.studyYear,
  });

  final int companyId;
  final String motivationText;
  final String? programme;
  final String? linkedin;
  final String? masterTitle;
  final int? studyYear;

  /// Validate motivation text length (requirement: ≤300 words)
  bool get isMotivationValid {
    final trimmed = motivationText.trim();
    if (trimmed.isEmpty) return false;
    final words = trimmed.split(RegExp(r'\s+'));
    return words.length <= 300;
  }

  /// Get word count for motivation text
  int get motivationWordCount {
    final trimmed = motivationText.trim();
    if (trimmed.isEmpty) return 0;
    final words = trimmed.split(RegExp(r'\s+'));
    return words.length;
  }

  /// Check if all required fields are provided
  bool get isValid {
    return companyId > 0 && motivationText.isNotEmpty && isMotivationValid;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentSessionApplicationParams &&
        other.companyId == companyId &&
        other.motivationText == motivationText &&
        other.programme == programme &&
        other.linkedin == linkedin &&
        other.masterTitle == masterTitle &&
        other.studyYear == studyYear;
  }

  @override
  int get hashCode {
    return Object.hash(
      companyId,
      motivationText,
      programme,
      linkedin,
      masterTitle,
      studyYear,
    );
  }

  @override
  String toString() {
    return 'StudentSessionApplicationParams(companyId: $companyId, motivationLength: ${motivationText.length})';
  }
}
