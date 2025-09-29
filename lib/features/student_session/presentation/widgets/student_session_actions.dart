import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_button.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/services/student_session_data_service.dart';
import '../../domain/services/student_session_status_service.dart';

/// Widget that displays appropriate actions based on authentication status and timeline
class StudentSessionActions extends StatelessWidget {
  final StudentSession session;
  final VoidCallback onApply;
  final VoidCallback onViewTimeslots;

  const StudentSessionActions({
    super.key,
    required this.session,
    required this.onApply,
    required this.onViewTimeslots,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final isAuthenticated = authViewModel.isAuthenticated;

        if (isAuthenticated) {
          // Show session-specific actions for authenticated users
          return _buildAuthenticatedActions(context);
        } else {
          // Show authentication prompt for unauthenticated users
          return _buildAuthenticationPrompt(context);
        }
      },
    );
  }

  Widget _buildAuthenticatedActions(BuildContext context) {
    // Create a session with application state for status checking
    final sessionWithApp = StudentSessionWithApplicationState(session: session);

    final actionInfo = StudentSessionStatusService.instance.getActionButtonInfo(
      sessionWithApp,
    );

    if (actionInfo.action == ActionType.none) {
      return const SizedBox.shrink();
    }

    return ArkadButton(
      text: actionInfo.text,
      onPressed: actionInfo.isEnabled
          ? () {
              switch (actionInfo.action) {
                case ActionType.apply:
                  onApply();
                case ActionType.bookTimeslot:
                case ActionType.manageBooking:
                  onViewTimeslots();
                case ActionType.none:
                  // No action needed
                  break;
              }
            }
          : null,
      fullWidth: true,
    );
  }

  Widget _buildAuthenticationPrompt(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: ArkadColors.arkadTurkos,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sign in to apply for student sessions and book timeslots',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: ArkadColors.arkadTurkos,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ArkadButton(
          text: 'Sign In',
          onPressed: () => _navigateToSignIn(context),
          fullWidth: true,
        ),
      ],
    );
  }

  void _navigateToSignIn(BuildContext context) {
    StatefulNavigationShell.of(context).goBranch(5);
  }
}

/// Timeline-aware wrapper for student session actions
class TimelineAwareStudentSessionActions extends StatelessWidget {
  final StudentSession session;
  final VoidCallback onApply;
  final VoidCallback onViewTimeslots;

  const TimelineAwareStudentSessionActions({
    super.key,
    required this.session,
    required this.onApply,
    required this.onViewTimeslots,
  });

  @override
  Widget build(BuildContext context) {
    final timelineStatus = TimelineValidationService.getCurrentStatus();

    return Consumer<AuthViewModel>(
      builder: (context, authViewModel, child) {
        final isAuthenticated = authViewModel.isAuthenticated;

        if (!isAuthenticated) {
          return StudentSessionActions(
            session: session,
            onApply: onApply,
            onViewTimeslots: onViewTimeslots,
          );
        }

        // For authenticated users, check timeline status
        if (!timelineStatus.canApply && !timelineStatus.canBook) {
          return _buildTimelineInfo(context, timelineStatus);
        }

        return StudentSessionActions(
          session: session,
          onApply: onApply,
          onViewTimeslots: onViewTimeslots,
        );
      },
    );
  }

  Widget _buildTimelineInfo(
    BuildContext context,
    TimelineStatus timelineStatus,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              timelineStatus.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
