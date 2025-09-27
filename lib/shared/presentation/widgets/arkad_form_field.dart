import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../shared/presentation/themes/arkad_theme.dart';

/// Unified form field component for the Arkad application
/// Provides consistent styling, validation, and behavior across all forms
class ArkadFormField extends StatefulWidget {
  const ArkadFormField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.helperText,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.obscureText = false,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.inputFormatters,
    this.focusNode,
    this.showValidationIcon = true,
    this.validationDelay = const Duration(milliseconds: 500),
    this.fieldType = ArkadFormFieldType.text,
    this.toggleObscureText,
  });

  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool obscureText;
  final bool enabled;
  final bool readOnly;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int? maxLines;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final bool showValidationIcon;
  final Duration validationDelay;
  final ArkadFormFieldType fieldType;
  final VoidCallback? toggleObscureText;

  @override
  State<ArkadFormField> createState() => _ArkadFormFieldState();
}

class _ArkadFormFieldState extends State<ArkadFormField> {
  String? _validationError;
  bool _isValidating = false;
  bool _hasBeenTouched = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          decoration: _buildInputDecoration(theme, colorScheme),
          validator: widget.validator,
          onChanged: _handleOnChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          obscureText: widget.obscureText,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          keyboardType: _getKeyboardType(),
          textInputAction:
              widget.textInputAction ?? _getDefaultTextInputAction(),
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters:
              widget.inputFormatters ?? _getDefaultInputFormatters(),
          style: theme.textTheme.bodyLarge,
        ),
        if (_isValidating)
          const Padding(
            padding: EdgeInsets.only(top: 8.0, left: 12.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    final hasError = _validationError != null;

    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      helperText: widget.helperText,
      errorText: _validationError,

      // Content padding for consistent sizing
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      isDense: true,
      alignLabelWithHint: true,

      // Prefix icon styling
      prefixIcon: widget.prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 8.0),
              child: Icon(
                widget.prefixIcon,
                color: hasError ? colorScheme.error : ArkadColors.arkadTurkos,
                size: 24,
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(minWidth: 50),

      // Suffix icon handling
      suffixIcon: _buildSuffixIcon(colorScheme, hasError),
      suffixIconConstraints: const BoxConstraints(minWidth: 40),

      // Error styling
      errorStyle: TextStyle(
        color: colorScheme.error,
        fontSize: 12,
        fontFamily: 'MyriadProCondensed',
      ),

      // Helper text styling
      helperStyle: TextStyle(
        color: theme.hintColor,
        fontSize: 12,
        fontFamily: 'MyriadProCondensed',
      ),

      // Border styling
      border: _buildBorder(colorScheme, false),
      enabledBorder: _buildBorder(colorScheme, false),
      focusedBorder: _buildBorder(colorScheme, false, focused: true),
      errorBorder: _buildBorder(colorScheme, true),
      focusedErrorBorder: _buildBorder(colorScheme, true, focused: true),
      disabledBorder: _buildBorder(colorScheme, false, disabled: true),

      // Fill styling
      filled: true,
      fillColor: _getFillColor(theme, hasError),
    );
  }

  Widget? _buildSuffixIcon(ColorScheme colorScheme, bool hasError) {
    // If custom suffix icon is provided, use it
    if (widget.suffixIcon != null) return widget.suffixIcon;

    // For password fields, show toggle visibility icon
    if (widget.fieldType == ArkadFormFieldType.password) {
      return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: IconButton(
          icon: Icon(
            widget.obscureText ? Icons.visibility_off : Icons.visibility,
            color: ArkadColors.arkadTurkos,
            size: 24,
          ),
          onPressed: widget.toggleObscureText,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      );
    }

    // Show validation icon if enabled and field has been touched
    if (widget.showValidationIcon &&
        _hasBeenTouched &&
        widget.controller?.text.isNotEmpty == true) {
      final isValid = _validationError == null && !_isValidating;
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: Icon(
          isValid ? Icons.check_circle : Icons.error,
          color: isValid ? ArkadColors.arkadGreen : colorScheme.error,
          size: 24,
        ),
      );
    }

    return null;
  }

  OutlineInputBorder _buildBorder(
    ColorScheme colorScheme,
    bool hasError, {
    bool focused = false,
    bool disabled = false,
  }) {
    Color borderColor;
    double borderWidth = 1.5;

    if (disabled) {
      borderColor = ArkadColors.lightGray;
      borderWidth = 1;
    } else if (hasError) {
      borderColor = colorScheme.error;
      borderWidth = focused ? 2 : 1.5;
    } else if (focused) {
      borderColor = ArkadColors.arkadTurkos;
      borderWidth = 2;
    } else {
      borderColor = ArkadColors.lightGray;
      borderWidth = 1;
    }

    return OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: borderWidth),
      borderRadius: BorderRadius.circular(12),
    );
  }

  Color _getFillColor(ThemeData theme, bool hasError) {
    if (hasError) {
      return theme.colorScheme.error.withValues(alpha: 0.05);
    }

    return theme.brightness == Brightness.dark
        ? ArkadColors.gray.withValues(alpha: 0.1)
        : ArkadColors.lightGray.withValues(alpha: 0.1);
  }

  TextInputType _getKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType!;

    return switch (widget.fieldType) {
      ArkadFormFieldType.email => TextInputType.emailAddress,
      ArkadFormFieldType.password => TextInputType.visiblePassword,
      ArkadFormFieldType.phone => TextInputType.phone,
      ArkadFormFieldType.number => TextInputType.number,
      ArkadFormFieldType.url => TextInputType.url,
      ArkadFormFieldType.multiline => TextInputType.multiline,
      _ => TextInputType.text,
    };
  }

  TextInputAction _getDefaultTextInputAction() {
    return switch (widget.fieldType) {
      ArkadFormFieldType.multiline => TextInputAction.newline,
      _ => TextInputAction.next,
    };
  }

  List<TextInputFormatter>? _getDefaultInputFormatters() {
    if (widget.inputFormatters != null) return widget.inputFormatters;

    return switch (widget.fieldType) {
      ArkadFormFieldType.phone => [FilteringTextInputFormatter.digitsOnly],
      ArkadFormFieldType.number => [FilteringTextInputFormatter.digitsOnly],
      ArkadFormFieldType.email => [
        FilteringTextInputFormatter.deny(RegExp(r'\s')),
      ],
      _ => null,
    };
  }

  void _handleOnChanged(String value) {
    if (!_hasBeenTouched) {
      setState(() {
        _hasBeenTouched = true;
      });
    }

    widget.onChanged?.call(value);

    // Perform debounced validation if validator is provided
    if (widget.validator != null) {
      _performDebouncedValidation(value);
    }
  }

  void _performDebouncedValidation(String value) {
    setState(() {
      _isValidating = true;
    });

    // Cancel previous validation
    Future.delayed(widget.validationDelay, () {
      if (mounted && widget.controller?.text == value) {
        final error = widget.validator?.call(value);
        if (mounted) {
          setState(() {
            _validationError = error;
            _isValidating = false;
          });
        }
      }
    });
  }
}

/// Types of form fields for automatic keyboard and validation configuration
enum ArkadFormFieldType { text, email, password, phone, number, url, multiline }

/// Helper class for common form field configurations
class ArkadFormFieldConfig {
  static ArkadFormField email({
    required TextEditingController controller,
    String labelText = 'Email',
    String? hintText = 'Enter your email address',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return ArkadFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icons.email_outlined,
      fieldType: ArkadFormFieldType.email,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  static ArkadFormField password({
    required TextEditingController controller,
    required bool obscureText,
    required VoidCallback toggleObscureText,
    String labelText = 'Password',
    String? hintText = 'Enter your password',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function(String)? onFieldSubmitted,
  }) {
    return ArkadFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icons.lock_outlined,
      fieldType: ArkadFormFieldType.password,
      obscureText: obscureText,
      toggleObscureText: toggleObscureText,
      validator: validator,
      onChanged: onChanged,
      onFieldSubmitted: onFieldSubmitted,
    );
  }

  static ArkadFormField phone({
    required TextEditingController controller,
    String labelText = 'Phone Number',
    String? hintText = 'Enter your phone number',
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return ArkadFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icons.phone_outlined,
      fieldType: ArkadFormFieldType.phone,
      validator: validator,
      onChanged: onChanged,
    );
  }

  static ArkadFormField text({
    required TextEditingController controller,
    required String labelText,
    String? hintText,
    String? helperText,
    IconData? prefixIcon,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
    int? maxLength,
  }) {
    return ArkadFormField(
      controller: controller,
      labelText: labelText,
      hintText: hintText,
      helperText: helperText,
      prefixIcon: prefixIcon,
      validator: validator,
      onChanged: onChanged,
      readOnly: readOnly,
      maxLength: maxLength,
    );
  }
}
