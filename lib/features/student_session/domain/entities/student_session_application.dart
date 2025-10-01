import 'timeslot.dart';

/// Domain entity representing a student session application
/// Contains both the application data and its current status
class StudentSessionApplication {
  const StudentSessionApplication({
    this.id,
    required this.companyId,
    required this.companyName,
    required this.motivationText,
    this.programme,
    this.linkedin,
    this.masterTitle,
    this.studyYear,
    required this.status,
    this.cvUrl,
    this.createdAt,
    this.updatedAt,
  });

  /// Optional ID (may not be available from all API responses)
  final int? id;

  /// Company ID this application is for
  final int companyId;

  /// Company name for display
  final String companyName;

  /// Student's motivation text (max 300 words as per requirements)
  final String motivationText;

  /// Student's programme (optional)
  final String? programme;

  /// Student's LinkedIn profile (optional)
  final String? linkedin;

  /// Student's master's title (optional)
  final String? masterTitle;

  /// Student's study year (optional)
  final int? studyYear;

  /// Current status of this application
  final ApplicationStatus status;

  /// URL to uploaded CV file (optional)
  final String? cvUrl;

  /// When this application was created
  final DateTime? createdAt;

  /// When this application was last updated
  final DateTime? updatedAt;

  /// Get word count for motivation text
  int get motivationWordCount {
    if (motivationText.isEmpty) return 0;
    final words = motivationText.trim().split(RegExp(r'\s+'));
    return words.length;
  }

  /// Check if motivation text meets requirements (≤300 words)
  bool get isMotivationValid => motivationWordCount <= 300;

  /// Create a copy with updated values
  StudentSessionApplication copyWith({
    int? id,
    int? companyId,
    String? companyName,
    String? motivationText,
    String? programme,
    String? linkedin,
    String? masterTitle,
    int? studyYear,
    ApplicationStatus? status,
    String? cvUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentSessionApplication(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      motivationText: motivationText ?? this.motivationText,
      programme: programme ?? this.programme,
      linkedin: linkedin ?? this.linkedin,
      masterTitle: masterTitle ?? this.masterTitle,
      studyYear: studyYear ?? this.studyYear,
      status: status ?? this.status,
      cvUrl: cvUrl ?? this.cvUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if application is editable
  bool get canEdit => status == ApplicationStatus.pending;

  /// Check if this application has a booking
  /// Note: The actual implementation is in the repository layer that checks timeslots
  /// This is a placeholder that will be overridden by repository logic
  bool get hasBooking => false;

  /// Check if this application can be booked (accepted but not yet booked)
  /// Note: The actual booking state is determined by repository logic checking timeslots
  bool get canBook => status == ApplicationStatus.accepted;

  /// Check if this application can cancel booking (accepted and booked)
  /// Note: The actual booking state is determined by repository logic checking timeslots
  bool get canCancelBooking => status == ApplicationStatus.accepted;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StudentSessionApplication &&
        other.id == id &&
        other.companyId == companyId &&
        other.companyName == companyName &&
        other.motivationText == motivationText &&
        other.programme == programme &&
        other.linkedin == linkedin &&
        other.masterTitle == masterTitle &&
        other.studyYear == studyYear &&
        other.status == status &&
        other.cvUrl == cvUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      companyId,
      companyName,
      motivationText,
      programme,
      linkedin,
      masterTitle,
      studyYear,
      status,
      cvUrl,
    );
  }

  @override
  String toString() {
    return 'StudentSessionApplication(id: $id, companyName: $companyName, status: $status)';
  }
}

/// Enhanced application entity with real booking state from timeslots
/// This provides the actual booking information determined from API timeslots
class StudentSessionApplicationWithBookingState {
  const StudentSessionApplicationWithBookingState({
    required this.application,
    required this.hasBooking,
    this.bookedTimeslot,
  });

  /// The base application entity
  final StudentSessionApplication application;

  /// Whether this application has a timeslot booking (determined from API)
  final bool hasBooking;

  /// The specific timeslot that is booked (if any)
  final Timeslot? bookedTimeslot;

  /// Check if this application can be booked (accepted but not yet booked)
  bool get canBook =>
      application.status == ApplicationStatus.accepted && !hasBooking;

  /// Check if this application can cancel booking (accepted and booked)
  bool get canCancelBooking =>
      application.status == ApplicationStatus.accepted && hasBooking;

  /// Check if this application can rebook (accepted and currently booked)
  bool get canRebook =>
      application.status == ApplicationStatus.accepted && hasBooking;

  @override
  String toString() {
    return 'StudentSessionApplicationWithBookingState(application: ${application.companyName}, hasBooking: $hasBooking)';
  }
}

/// Status of a student session application
/// Maps from StudentSessionNormalUserSchemaUserStatusEnum in API
enum ApplicationStatus {
  pending('pending'),
  accepted('accepted'), // API uses 'accepted' not 'approved'
  rejected('rejected');

  const ApplicationStatus(this.value);

  final String value;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  /// Create from API string value
  static ApplicationStatus? fromValue(String? value) {
    if (value == null) return null;
    for (final status in ApplicationStatus.values) {
      if (status.value == value) return status;
    }
    return null;
  }

  /// Check if status is positive (accepted)
  bool get isPositive => this == ApplicationStatus.accepted;

  /// Check if status is negative (rejected)
  bool get isNegative => this == ApplicationStatus.rejected;

  /// Check if status allows further actions
  bool get allowsActions =>
      this == ApplicationStatus.pending || this == ApplicationStatus.accepted;
}
