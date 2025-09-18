/// Domain entity representing a student session application
class StudentSessionApplication {
  final int? id;
  final int companyId;
  final String companyName;
  final String motivationText;
  final String? programme;
  final String? linkedin;
  final String? masterTitle;
  final int? studyYear;
  final ApplicationStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    this.createdAt,
    this.updatedAt,
  });

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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if application can be cancelled
  bool get canCancel =>
      status == ApplicationStatus.pending ||
      status == ApplicationStatus.approved;

  /// Check if application is editable
  bool get canEdit => status == ApplicationStatus.pending;

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
        other.status == status;
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
    );
  }

  @override
  String toString() {
    return 'StudentSessionApplication(id: $id, companyName: $companyName, status: $status)';
  }
}

/// Status of a student session application
enum ApplicationStatus {
  pending,
  approved,
  rejected,
  cancelled;

  /// Display name for UI
  String get displayName {
    switch (this) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Check if status is positive (approved)
  bool get isPositive => this == ApplicationStatus.approved;

  /// Check if status is negative (rejected/cancelled)
  bool get isNegative =>
      this == ApplicationStatus.rejected || this == ApplicationStatus.cancelled;
}
