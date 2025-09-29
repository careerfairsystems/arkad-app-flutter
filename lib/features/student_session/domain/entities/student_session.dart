import 'field_configuration.dart';

/// Domain entity representing a student session for a company
/// Maps from StudentSessionNormalUserSchema in API
class StudentSession {
  const StudentSession({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.isAvailable,
    this.bookingCloseTime,
    this.userStatus,
    this.logoUrl,
    this.description,
    this.disclaimer,
    this.fieldConfigurations = const [],
  });

  /// Unique identifier for this student session
  final int id;

  /// ID of the company offering this session
  final int companyId;

  /// Name of the company (for display purposes)
  final String companyName;

  /// Whether this session is available for applications/booking
  final bool isAvailable;

  /// When booking closes for this session (null if no booking period)
  final DateTime? bookingCloseTime;

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

  /// Check if user has applied to this session
  bool get hasApplied => userStatus != null;

  /// Check if user's application is pending
  bool get isPending => userStatus == StudentSessionStatus.pending;

  /// Check if user's application was accepted
  bool get isAccepted => userStatus == StudentSessionStatus.accepted;

  /// Check if user's application was rejected
  bool get isRejected => userStatus == StudentSessionStatus.rejected;

  /// Check if user can apply to this session
  bool get canApply => isAvailable && !hasApplied;

  /// Check if user can book timeslots (must be accepted)
  bool get canBook => isAccepted && _isBookingPeriodActive;

  /// Check if booking period is currently active
  bool get _isBookingPeriodActive {
    if (bookingCloseTime == null) return false;
    return DateTime.now().isBefore(bookingCloseTime!);
  }

  /// Get user-friendly status message
  String get statusMessage {
    if (!isAvailable) return 'Session not available';

    switch (userStatus) {
      case StudentSessionStatus.pending:
        return 'Application pending review';
      case StudentSessionStatus.accepted:
        return canBook ? 'Ready to book timeslot' : 'Booking period closed';
      case StudentSessionStatus.rejected:
        return 'Application not accepted';
      case null:
        return 'Available to apply';
    }
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
    DateTime? bookingCloseTime,
    StudentSessionStatus? userStatus,
    String? logoUrl,
    String? description,
    String? disclaimer,
    List<FieldConfiguration>? fieldConfigurations,
  }) {
    return StudentSession(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      isAvailable: isAvailable ?? this.isAvailable,
      bookingCloseTime: bookingCloseTime ?? this.bookingCloseTime,
      userStatus: userStatus ?? this.userStatus,
      logoUrl: logoUrl ?? this.logoUrl,
      description: description ?? this.description,
      disclaimer: disclaimer ?? this.disclaimer,
      fieldConfigurations: fieldConfigurations ?? this.fieldConfigurations,
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
        other.bookingCloseTime == bookingCloseTime &&
        other.userStatus == userStatus &&
        other.logoUrl == logoUrl &&
        other.description == description &&
        other.disclaimer == disclaimer &&
        _listEquals(other.fieldConfigurations, fieldConfigurations);
  }

  /// Helper method for deep list equality comparison
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int index = 0; index < a.length; index++) {
      if (a[index] != b[index]) return false;
    }
    return true;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      companyName,
      isAvailable,
      bookingCloseTime,
      userStatus,
      logoUrl,
      description,
      disclaimer,
      _listHashCode(fieldConfigurations),
    );
  }

  /// Helper method for deep list hash code computation
  int _listHashCode<T>(List<T>? list) {
    if (list == null) return 0;
    int hash = 0;
    for (int i = 0; i < list.length; i++) {
      hash = hash ^ list[i].hashCode;
    }
    return hash;
  }

  @override
  String toString() {
    return 'StudentSession(id: $id, companyName: $companyName, status: $userStatus, available: $isAvailable)';
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
    if (motivationText.isEmpty) return false;
    final words = motivationText.trim().split(RegExp(r'\s+'));
    return words.length <= 300;
  }

  /// Get word count for motivation text
  int get motivationWordCount {
    if (motivationText.isEmpty) return 0;
    final words = motivationText.trim().split(RegExp(r'\s+'));
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
