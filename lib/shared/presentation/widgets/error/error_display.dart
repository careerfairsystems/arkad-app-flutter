import 'package:flutter/material.dart';

import '../../../errors/app_error.dart';

/// Flexible, reusable error display widget
class ErrorDisplay extends StatelessWidget {
  const ErrorDisplay({
    super.key,
    required this.error,
    this.onDismiss,
    this.showIcon = true,
    this.padding = const EdgeInsets.all(16),
  });

  final AppError error;
  final VoidCallback? onDismiss;
  final bool showIcon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Card(
      color: _getErrorColor(error.severity, colorScheme),
      elevation: 2,
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showIcon) ...[
                  Icon(
                    _getErrorIcon(error.severity),
                    color: _getIconColor(error.severity, colorScheme),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    error.userMessage,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _getTextColor(error.severity, colorScheme),
                    ),
                  ),
                ),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: _getIconColor(error.severity, colorScheme),
                  ),
              ],
            ),
            if (error.recoveryActions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: error.recoveryActions.map((action) {
                  return action.isPrimary
                      ? ElevatedButton.icon(
                          onPressed: action.action,
                          icon: action.icon != null 
                              ? Icon(action.icon, size: 16) 
                              : null,
                          label: Text(action.label),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 8,
                            ),
                          ),
                        )
                      : TextButton.icon(
                          onPressed: action.action,
                          icon: action.icon != null 
                              ? Icon(action.icon, size: 16) 
                              : null,
                          label: Text(action.label),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16, 
                              vertical: 8,
                            ),
                          ),
                        );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getErrorColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primaryContainer;
      case ErrorSeverity.warning:
        return colorScheme.tertiaryContainer;
      case ErrorSeverity.error:
        return colorScheme.errorContainer;
      case ErrorSeverity.critical:
        return colorScheme.error.withValues(alpha: 0.1);
    }
  }

  Color _getTextColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.onPrimaryContainer;
      case ErrorSeverity.warning:
        return colorScheme.onTertiaryContainer;
      case ErrorSeverity.error:
        return colorScheme.onErrorContainer;
      case ErrorSeverity.critical:
        return colorScheme.error;
    }
  }

  Color _getIconColor(ErrorSeverity severity, ColorScheme colorScheme) {
    switch (severity) {
      case ErrorSeverity.info:
        return colorScheme.primary;
      case ErrorSeverity.warning:
        return colorScheme.tertiary;
      case ErrorSeverity.error:
        return colorScheme.error;
      case ErrorSeverity.critical:
        return colorScheme.error;
    }
  }

  IconData _getErrorIcon(ErrorSeverity severity) {
    switch (severity) {
      case ErrorSeverity.info:
        return Icons.info_outline;
      case ErrorSeverity.warning:
        return Icons.warning_amber_outlined;
      case ErrorSeverity.error:
        return Icons.error_outline;
      case ErrorSeverity.critical:
        return Icons.dangerous_outlined;
    }
  }
}

/// Compact inline error display for form fields
class InlineErrorDisplay extends StatelessWidget {
  const InlineErrorDisplay({
    super.key,
    required this.error,
    this.showIcon = true,
  });

  final AppError error;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (showIcon) ...[
            Icon(
              Icons.error_outline,
              color: colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              error.userMessage,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}