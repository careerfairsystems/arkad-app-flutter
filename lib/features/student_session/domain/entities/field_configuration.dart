/// Domain entity representing field configuration for Student Session applications.
/// 
/// This entity encapsulates the configuration for individual form fields in the
/// Student Session application form, controlling their visibility, requirement level,
/// and validation behavior based on company-specific settings from the backend API.
/// 
/// The field configuration determines:
/// - Whether a field should be displayed (visible/hidden)
/// - Whether a field is required for form submission
/// - How validation should be applied to the field
/// 
/// This supports dynamic form rendering based on `FieldModification` data from the API,
/// allowing companies to customize which fields are shown to applicants.
class FieldConfiguration {
  /// Creates a field configuration with validation.
  /// 
  /// Throws [ArgumentError] if [fieldName] is empty, as this would indicate
  /// invalid API data that could cause form rendering issues.
  const FieldConfiguration({required this.fieldName, required this.level})
      : assert(fieldName.length > 0, 'Field name cannot be empty');

  /// Name of the field (e.g., 'programme', 'linkedin', 'masterTitle')
  final String fieldName;

  /// Level determining field behavior (required, optional, hidden)
  final FieldLevel level;

  /// Check if field should be displayed in the form
  bool get isVisible => level != FieldLevel.hidden;

  /// Check if field is required for form submission
  bool get isRequired => level == FieldLevel.required;

  /// Check if field is optional (visible but not required)
  bool get isOptional => level == FieldLevel.optional;

  /// Check if field should be hidden from the form
  bool get isHidden => level == FieldLevel.hidden;

  /// Get the required indicator for UI display
  String get requiredIndicator => isRequired ? ' *' : '';

  /// Create a copy with updated values
  FieldConfiguration copyWith({String? fieldName, FieldLevel? level}) {
    return FieldConfiguration(
      fieldName: fieldName ?? this.fieldName,
      level: level ?? this.level,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FieldConfiguration &&
        other.fieldName == fieldName &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(fieldName, level);

  @override
  String toString() {
    return 'FieldConfiguration(fieldName: $fieldName, level: $level)';
  }
}

/// Level determining field behavior in the application form
enum FieldLevel {
  /// Field is required and must be filled
  required('required'),

  /// Field is optional and can be left empty
  optional('optional'),

  /// Field is hidden and should not be displayed
  hidden('hidden');

  const FieldLevel(this.value);

  /// API string value for this field level
  final String value;

  /// Create FieldLevel from API string value
  static FieldLevel fromValue(String value) {
    switch (value) {
      case 'required':
        return FieldLevel.required;
      case 'optional':
        return FieldLevel.optional;
      case 'hidden':
        return FieldLevel.hidden;
      default:
        // Default to required for unknown values to ensure form validation
        return FieldLevel.required;
    }
  }

  /// Display name for UI (if needed)
  String get displayName {
    switch (this) {
      case FieldLevel.required:
        return 'Required';
      case FieldLevel.optional:
        return 'Optional';
      case FieldLevel.hidden:
        return 'Hidden';
    }
  }
}
