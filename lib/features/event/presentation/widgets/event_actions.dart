import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/event_status.dart';
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
        final status = event.status ?? EventStatus.notBooked;

        switch (status) {
          case EventStatus.notBooked:
            return _buildNotBookedEventActions(context, viewModel);
          case EventStatus.booked:
            return _buildBookedEventActions(context, viewModel);
          case EventStatus.ticketUsed:
            return _buildTicketUsedEventActions(context);
        }
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
              const Icon(
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
                ).textTheme.bodyMedium?.copyWith(color: ArkadColors.gray),
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
                onPressed: viewModel.isLoading
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

  Widget _buildNotBookedEventActions(
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

  Widget _buildTicketUsedEventActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArkadColors.arkadNavy.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArkadColors.arkadNavy.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available,
            color: ArkadColors.arkadNavy,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'You have attended this event',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: ArkadColors.arkadNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Your ticket has been used and you have successfully attended this event',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: ArkadColors.gray),
            textAlign: TextAlign.center,
          ),
        ],
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
              const Icon(
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
                ).textTheme.bodyMedium?.copyWith(color: ArkadColors.gray),
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
    StatefulNavigationShell.of(context).goBranch(5);
  }

  void _showTicket(BuildContext context) {
    context.go('/events/detail/${event.id}/ticket');
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
          builder: (context) => AlertDialog(
            title: const Text('Deregister from Event'),
            content: Text(
              'Are you sure you want to deregister from "${event.title}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => context.pop(true),
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
