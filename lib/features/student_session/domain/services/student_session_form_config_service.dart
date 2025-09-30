import '../entities/field_configuration.dart';

/// Service for managing dynamic form configuration in Student Session applications.
///
/// This service handles the business logic for determining how form fields should
/// behave based on `FieldConfiguration` data received from the backend API. It provides
/// methods to:
///
/// - Determine field visibility (shown/hidden)
/// - Check field requirement levels (required/optional)
/// - Generate appropriate validators for form fields
/// - Organize fields into required and optional sections
/// - Validate complete form submission
///
/// The service supports dynamic form rendering where companies can customize
/// which fields are shown to Student Session applicants through backend configuration.
///
/// Example usage:
/// ```dart
/// final formConfig = StudentSessionFormConfigService(
///   fieldConfigurations: session.fieldConfigurations,
/// );
///
/// if (formConfig.shouldShowField('programme')) {
///   // Show programme field
///   final validator = formConfig.getDropdownValidator('programme');
/// }
/// ```
class StudentSessionFormConfigService {
  /// Creates a form configuration service with the provided field configurations.
  ///
  /// Optimizes field lookup by creating an internal map for O(1) access.
  ///
  /// Throws [ArgumentError] if [fieldConfigurations] contains duplicate field names,
  /// as this would indicate malformed API data that could cause unpredictable behavior.
  StudentSessionFormConfigService({required this.fieldConfigurations})
    : _fieldConfigMap = _createFieldMap(fieldConfigurations);

  /// Creates and validates the field configuration map.
  ///
  /// Ensures no duplicate field names exist in the configuration,
  /// which could cause unpredictable form behavior.
  static Map<String, FieldConfiguration> _createFieldMap(
    List<FieldConfiguration> configs,
  ) {
    final map = <String, FieldConfiguration>{};

    for (final config in configs) {
      if (map.containsKey(config.fieldName)) {
        throw ArgumentError(
          'Duplicate field configuration found for field: ${config.fieldName}. '
          'This indicates malformed API data.',
        );
      }
      map[config.fieldName] = config;
    }

    return map;
  }

  /// List of field configurations from the API
  final List<FieldConfiguration> fieldConfigurations;

  /// Internal map for O(1) field configuration lookup
  final Map<String, FieldConfiguration> _fieldConfigMap;

  /// Get field configuration for a specific field name.
  ///
  /// Uses optimized O(1) map lookup instead of linear search.
  /// Returns null if no configuration exists for the given field name.
  FieldConfiguration? getFieldConfiguration(String fieldName) {
    return _fieldConfigMap[fieldName];
  }

  /// Check if a field should be displayed (not hidden)
  bool shouldShowField(String fieldName) {
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

  /// Get the required indicator for UI display (* for required fields)
  String getRequiredIndicator(String fieldName) {
    return isFieldRequired(fieldName) ? ' *' : '';
  }

  /// Get the complete label text with required indicator
  String getFieldLabel(String baseLabel, String fieldName) {
    return '$baseLabel${getRequiredIndicator(fieldName)}';
  }

  /// Check if field should be shown in required section
  bool shouldShowInRequiredSection(String fieldName) {
    return shouldShowField(fieldName) && isFieldRequired(fieldName);
  }

  /// Check if field should be shown in optional section
  bool shouldShowInOptionalSection(String fieldName) {
    return shouldShowField(fieldName) && isFieldOptional(fieldName);
  }

  /// Get validation function for a specific field
  String? Function(String?)? getFieldValidator(String fieldName) {
    if (!shouldShowField(fieldName)) return null;
    if (!isFieldRequired(fieldName)) return null;

    // Return validation function for required fields
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return '${_getFieldDisplayName(fieldName)} is required';
      }
      return null;
    };
  }

  /// Get specific validation function for text fields with custom validation
  String? Function(String?)? getTextFieldValidator(
    String fieldName, {
    int? minLength,
    int? maxLength,
    String? customErrorMessage,
  }) {
    if (!shouldShowField(fieldName)) return null;

    return (String? value) {
      // Check if field is required
      if (isFieldRequired(fieldName) &&
          (value == null || value.trim().isEmpty)) {
        return customErrorMessage ??
            '${_getFieldDisplayName(fieldName)} is required';
      }

      // Skip further validation if field is optional and empty
      if (!isFieldRequired(fieldName) &&
          (value == null || value.trim().isEmpty)) {
        return null;
      }

      // Validate length if specified
      if (value != null) {
        if (minLength != null && value.trim().length < minLength) {
          return '${_getFieldDisplayName(fieldName)} must be at least $minLength characters';
        }
        if (maxLength != null && value.trim().length > maxLength) {
          return '${_getFieldDisplayName(fieldName)} must be no more than $maxLength characters';
        }
      }

      return null;
    };
  }

  /// Get dropdown validation function
  String? Function(dynamic)? getDropdownValidator(String fieldName) {
    if (!shouldShowField(fieldName)) return null;
    if (!isFieldRequired(fieldName)) return null;

    return (dynamic value) {
      if (value == null) {
        return '${_getFieldDisplayName(fieldName)} is required';
      }
      return null;
    };
  }

  /// Get list of all visible fields
  List<String> getVisibleFields() {
    return fieldConfigurations
        .where((config) => config.isVisible)
        .map((config) => config.fieldName)
        .toList();
  }

  /// Get list of all required visible fields
  List<String> getRequiredVisibleFields() {
    return fieldConfigurations
        .where((config) => config.isVisible && config.isRequired)
        .map((config) => config.fieldName)
        .toList();
  }

  /// Get list of all optional visible fields
  List<String> getOptionalVisibleFields() {
    return fieldConfigurations
        .where((config) => config.isVisible && config.isOptional)
        .map((config) => config.fieldName)
        .toList();
  }

  /// Check if there are any required fields to show
  bool get hasRequiredFields => getRequiredVisibleFields().isNotEmpty;

  /// Check if there are any optional fields to show
  bool get hasOptionalFields => getOptionalVisibleFields().isNotEmpty;

  /// Validate that all required visible fields have values
  bool validateRequiredFields(Map<String, dynamic> fieldValues) {
    for (final fieldName in getRequiredVisibleFields()) {
      final value = fieldValues[fieldName];
      if (!_isFieldValueValid(value)) {
        return false;
      }
    }
    return true;
  }

  /// Check if a field value is valid (not null/empty/missing)
  bool _isFieldValueValid(dynamic value) {
    if (value == null) return false;

    // Handle string fields (most common)
    if (value is String) {
      return value.trim().isNotEmpty;
    }

    // Handle file fields (PlatformFile objects)
    // For files, just check if the object exists - validation happens elsewhere
    return true;
  }

  /// Get list of missing required fields
  List<String> getMissingRequiredFields(Map<String, dynamic> fieldValues) {
    final missingFields = <String>[];
    for (final fieldName in getRequiredVisibleFields()) {
      final value = fieldValues[fieldName];
      if (!_isFieldValueValid(value)) {
        missingFields.add(_getFieldDisplayName(fieldName));
      }
    }
    return missingFields;
  }

  /// Get user-friendly display name for field
  String _getFieldDisplayName(String fieldName) {
    switch (fieldName) {
      case 'programme':
        return 'Programme';
      case 'linkedin':
        return 'LinkedIn Profile';
      case 'masterTitle':
        return 'Master\'s Title';
      case 'studyYear':
        return 'Study Year';
      case 'motivationText':
        return 'Motivation';
      case 'cv':
        return 'CV';
      default:
        // Capitalize first letter and replace camelCase with spaces
        return fieldName[0].toUpperCase() +
            fieldName
                .substring(1)
                .replaceAllMapped(
                  RegExp(r'([A-Z])'),
                  (match) => ' ${match.group(0)}',
                );
    }
  }

  /// Create a copy with different field configurations
  StudentSessionFormConfigService copyWith({
    List<FieldConfiguration>? fieldConfigurations,
  }) {
    return StudentSessionFormConfigService(
      fieldConfigurations: fieldConfigurations ?? this.fieldConfigurations,
    );
  }

  @override
  String toString() {
    return 'StudentSessionFormConfigService(configurations: ${fieldConfigurations.length})';
  }
}
