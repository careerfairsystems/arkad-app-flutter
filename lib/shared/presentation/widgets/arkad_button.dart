import 'package:flutter/material.dart';

import '../../../shared/presentation/themes/arkad_theme.dart';

/// Unified button system for the Arkad application
/// Provides consistent styling and behavior across all buttons
class ArkadButton extends StatelessWidget {
  const ArkadButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = ArkadButtonVariant.primary,
    this.size = ArkadButtonSize.large,
    this.isLoading = false,
    this.icon,
    this.fullWidth = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final ArkadButtonVariant variant;
  final ArkadButtonSize size;
  final bool isLoading;
  final IconData? icon;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final buttonStyle = _getButtonStyle(theme, colorScheme);
    final textStyle = _getTextStyle(theme);
    final buttonSize = _getButtonSize();

    Widget child = _buildButtonContent(textStyle);

    final button = switch (variant) {
      ArkadButtonVariant.primary => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      ArkadButtonVariant.secondary => OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      ArkadButtonVariant.ghost => TextButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
      ArkadButtonVariant.danger => ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: buttonStyle,
        child: child,
      ),
    };

    if (fullWidth) {
      return SizedBox(
        width: double.infinity,
        height: buttonSize.height,
        child: button,
      );
    }

    return SizedBox(height: buttonSize.height, child: button);
  }

  Widget _buildButtonContent(TextStyle textStyle) {
    final loadingIndicator = SizedBox(
      width: textStyle.fontSize! * 1.2,
      height: textStyle.fontSize! * 1.2,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(
          variant == ArkadButtonVariant.primary ||
                  variant == ArkadButtonVariant.danger
              ? ArkadColors.white
              : ArkadColors.arkadTurkos,
        ),
      ),
    );

    if (isLoading) {
      return loadingIndicator;
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: textStyle.fontSize! * 1.2),
          const SizedBox(width: 8),
          Text(text, style: textStyle),
        ],
      );
    }

    return Text(text, style: textStyle);
  }

  ButtonStyle _getButtonStyle(ThemeData theme, ColorScheme colorScheme) {
    final buttonSize = _getButtonSize();
    final padding = EdgeInsets.symmetric(
      horizontal: buttonSize.horizontalPadding,
      vertical: buttonSize.verticalPadding,
    );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonSize.borderRadius),
    );

    return switch (variant) {
      ArkadButtonVariant.primary => ElevatedButton.styleFrom(
        backgroundColor: ArkadColors.arkadTurkos,
        foregroundColor: ArkadColors.white,
        padding: padding,
        shape: shape,
        elevation: 2,
        shadowColor: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
      ),
      ArkadButtonVariant.secondary => OutlinedButton.styleFrom(
        foregroundColor: ArkadColors.arkadTurkos,
        side: const BorderSide(color: ArkadColors.arkadTurkos, width: 1.5),
        padding: padding,
        shape: shape,
      ),
      ArkadButtonVariant.ghost => TextButton.styleFrom(
        foregroundColor: ArkadColors.arkadTurkos,
        padding: padding,
        shape: shape,
      ),
      ArkadButtonVariant.danger => ElevatedButton.styleFrom(
        backgroundColor: ArkadColors.lightRed,
        foregroundColor: ArkadColors.white,
        padding: padding,
        shape: shape,
        elevation: 2,
        shadowColor: ArkadColors.lightRed.withValues(alpha: 0.3),
      ),
    };
  }

  TextStyle _getTextStyle(ThemeData theme) {
    final fontSize = _getButtonSize().fontSize;

    // Get the appropriate text color based on variant
    final textColor = switch (variant) {
      ArkadButtonVariant.primary ||
      ArkadButtonVariant.danger => ArkadColors.white,
      ArkadButtonVariant.secondary ||
      ArkadButtonVariant.ghost => ArkadColors.arkadTurkos,
    };

    return theme.textTheme.labelLarge?.copyWith(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: textColor, // Explicitly set the text color
        ) ??
        TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          fontFamily: 'MyriadProCondensed',
          color: textColor, // Explicitly set the text color
        );
  }

  _ButtonSizeData _getButtonSize() {
    return switch (size) {
      ArkadButtonSize.small => const _ButtonSizeData(
        height: 36,
        fontSize: 14,
        horizontalPadding: 16,
        verticalPadding: 8,
        borderRadius: 8,
      ),
      ArkadButtonSize.medium => const _ButtonSizeData(
        height: 44,
        fontSize: 16,
        horizontalPadding: 20,
        verticalPadding: 10,
        borderRadius: 10,
      ),
      ArkadButtonSize.large => const _ButtonSizeData(
        height: 52,
        fontSize: 16,
        horizontalPadding: 24,
        verticalPadding: 12,
        borderRadius: 12,
      ),
    };
  }
}

/// Button variants following Arkad design system
enum ArkadButtonVariant {
  primary, // Filled button with brand color
  secondary, // Outlined button with brand color
  ghost, // Text button with brand color
  danger, // Filled button with error color
}

/// Button sizes
enum ArkadButtonSize {
  small, // Compact buttons for lists/cards
  medium, // Standard buttons
  large, // Prominent buttons for forms
}

/// Internal data class for button sizing
class _ButtonSizeData {
  const _ButtonSizeData({
    required this.height,
    required this.fontSize,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.borderRadius,
  });

  final double height;
  final double fontSize;
  final double horizontalPadding;
  final double verticalPadding;
  final double borderRadius;
}
