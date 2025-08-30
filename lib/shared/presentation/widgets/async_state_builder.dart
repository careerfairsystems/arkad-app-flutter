import 'package:flutter/material.dart';

import '../../errors/app_error.dart';
import '../commands/base_command.dart';

/// Builder widget that handles different states of a Command
class AsyncStateBuilder<T> extends StatelessWidget {
  const AsyncStateBuilder({
    super.key,
    required this.command,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.idleBuilder,
  });

  final Command<T> command;
  final Widget Function(BuildContext context, T result) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, AppError error)? errorBuilder;
  final Widget Function(BuildContext context)? idleBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: command,
      builder: (context, child) {
        if (command.isExecuting) {
          return loadingBuilder?.call(context) ?? 
              const Center(child: CircularProgressIndicator());
        }

        if (command.hasError) {
          return errorBuilder?.call(context, command.error!) ??
              _buildDefaultError(context, command.error!);
        }

        if (command.isCompleted && command.result != null) {
          return builder(context, command.result as T);
        }

        // Idle state (no result yet, no error, not executing)
        return idleBuilder?.call(context) ?? const SizedBox.shrink();
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, AppError error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => command.execute(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Builder for commands that don't return a result (VoidCommand)
class VoidAsyncStateBuilder extends StatelessWidget {
  const VoidAsyncStateBuilder({
    super.key,
    required this.command,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.idleBuilder,
  });

  final Command<void> command;
  final Widget Function(BuildContext context) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, AppError error)? errorBuilder;
  final Widget Function(BuildContext context)? idleBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: command,
      builder: (context, child) {
        if (command.isExecuting) {
          return loadingBuilder?.call(context) ?? 
              const Center(child: CircularProgressIndicator());
        }

        if (command.hasError) {
          return errorBuilder?.call(context, command.error!) ??
              _buildDefaultError(context, command.error!);
        }

        // For void commands, show content when completed or idle
        return builder(context);
      },
    );
  }

  Widget _buildDefaultError(BuildContext context, AppError error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              error.userMessage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => command.execute(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A simple loading indicator with message
class ArkadLoadingIndicator extends StatelessWidget {
  const ArkadLoadingIndicator({
    super.key,
    this.message,
    this.size = 24.0,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}