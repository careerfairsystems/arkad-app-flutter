import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../view_models/event_view_model.dart';

/// Widget that displays appropriate actions based on authentication status
class EventActions extends StatelessWidget {
  final Event event;
  final VoidCallback onRegister;

  const EventActions({
    super.key,
    required this.event,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show any actions if registration is not required
    if (!event.isRegistrationRequired) {
      return const SizedBox.shrink();
    }

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final isAuthenticated = authViewModel.isAuthenticated;

        if (isAuthenticated) {
          // Show register button for authenticated users
          return _buildRegisterButton(context);
        } else {
          // Show authentication prompt for unauthenticated users
          return _buildAuthenticationPrompt(context);
        }
      },
    );
  }

  Widget _buildRegisterButton(BuildContext context) {
    return Consumer<EventViewModel>(
      builder: (context, viewModel, child) {
        return FutureBuilder<bool?>(
          future: viewModel.isEventBooked(event.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                width: double.infinity,
                height: 48,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final isBooked = snapshot.data ?? false;

            if (isBooked) {
              return _buildBookedEventActions(context, viewModel);
            } else {
              return _buildUnbookedEventActions(context, viewModel);
            }
          },
        );
      },
    );
  }

  Widget _buildBookedEventActions(
    BuildContext context,
    EventViewModel viewModel,
  ) {
    return Column(
      children: [
        // Booking confirmation message
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArkadColors.arkadGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: ArkadColors.arkadGreen,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'You are registered for this event',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ArkadColors.arkadNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'You will receive updates and reminders about this event',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Action buttons
        Row(
          children: [
            Expanded(
              child: ArkadButton(
                text: 'Show Ticket',
                onPressed: () => _showTicket(context),
                icon: Icons.confirmation_number,
                variant: ArkadButtonVariant.secondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ArkadButton(
                text: 'Deregister',
                onPressed:
                    viewModel.isLoading
                        ? null
                        : () => _handleDeregister(context, viewModel),
                isLoading: viewModel.isLoading,
                icon: Icons.cancel_outlined,
                variant: ArkadButtonVariant.danger,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUnbookedEventActions(
    BuildContext context,
    EventViewModel viewModel,
  ) {
    final canRegister = event.canRegister;

    return SizedBox(
      width: double.infinity,
      child: ArkadButton(
        text: canRegister ? 'Register for Event' : 'Registration Closed',
        onPressed: canRegister && !viewModel.isLoading ? onRegister : null,
        isLoading: viewModel.isLoading,
        icon: canRegister ? Icons.event_available : Icons.event_busy,
      ),
    );
  }

  Widget _buildAuthenticationPrompt(BuildContext context) {
    return Column(
      children: [
        // Info card about authentication requirement
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.lock_outline,
                color: ArkadColors.arkadTurkos,
                size: 32,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in required',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: ArkadColors.arkadNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need to sign in or create an account to register for this event',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Sign in to register button
        SizedBox(
          width: double.infinity,
          child: ArkadButton(
            text: 'Sign In to Register',
            onPressed: () => _navigateToLoginTab(context),
            icon: Icons.login,
          ),
        ),
      ],
    );
  }

  void _navigateToLoginTab(BuildContext context) {
    // Find the StatefulNavigationShell in the widget tree
    final router = GoRouter.of(context);
    router.go('/auth/login');
  }

  void _showTicket(BuildContext context) {
    // TODO: Navigate to ticket screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ticket view will be implemented soon'),
        backgroundColor: ArkadColors.arkadTurkos,
      ),
    );
  }

  Future<void> _handleDeregister(
    BuildContext context,
    EventViewModel viewModel,
  ) async {
    final confirmed = await _showDeregisterConfirmationDialog(context);
    if (!confirmed) return;

    final success = await viewModel.unregisterFromEvent(event.id);

    if (context.mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deregistered from ${event.title}'),
            backgroundColor: ArkadColors.arkadGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to deregister from event: ${viewModel.error?.userMessage ?? 'Unknown error'}',
            ),
            backgroundColor: ArkadColors.lightRed,
          ),
        );
      }
    }
  }

  Future<bool> _showDeregisterConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Deregister from Event'),
                content: Text(
                  'Are you sure you want to deregister from "${event.title}"?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: ArkadColors.lightRed,
                    ),
                    child: const Text('Deregister'),
                  ),
                ],
              ),
        ) ??
        false;
  }
}
