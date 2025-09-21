import 'package:flutter/material.dart';

import '../../../../shared/presentation/widgets/async_state_builder.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../commands/get_student_sessions_command.dart';
import 'student_session_card.dart';

/// Student session list widget with loading/error states
class StudentSessionList extends StatelessWidget {
  const StudentSessionList({
    super.key,
    required this.command,
    required this.sessions,
    required this.applications,
    required this.onSessionTap,
    required this.onApply,
    required this.onViewTimeslots,
    this.onRefresh,
    this.emptyStateWidget,
    this.padding = const EdgeInsets.all(0),
  });

  final GetStudentSessionsCommand command;
  final List<StudentSession> sessions;
  final List<StudentSessionApplication> applications;
  final Function(StudentSession) onSessionTap;
  final Function(StudentSession) onApply;
  final Function(StudentSession) onViewTimeslots;
  final Future<void> Function()? onRefresh;
  final Widget? emptyStateWidget;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return AsyncStateBuilder<List<StudentSession>>(
      command: command,
      builder: (context, _) => _buildSessionList(context),
      loadingBuilder:
          (context) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading student sessions...'),
              ],
            ),
          ),
      errorBuilder: (context, error) => _buildErrorState(context),
    );
  }

  Widget _buildSessionList(BuildContext context) {
    if (sessions.isEmpty) {
      return emptyStateWidget ?? _buildEmptyState(context);
    }

    final widget = ListView.builder(
      padding: padding,
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        final application = _getApplicationForSession(session);

        return StudentSessionCard(
          session: session,
          application: application,
          onApply: () => onApply(session),
          onViewTimeslots: () => onViewTimeslots(session),
        );
      },
    );

    // Wrap with RefreshIndicator if refresh callback is provided
    if (onRefresh != null) {
      return RefreshIndicator(onRefresh: onRefresh!, child: widget);
    }

    return widget;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.people_rounded,
                size: 48,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No student sessions available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Student sessions will be available during the application period (October 13-26, 2025)',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load student sessions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Please check your connection and try again',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => command.loadStudentSessions(forceRefresh: true),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  /// Find the application for a specific session
  StudentSessionApplication? _getApplicationForSession(StudentSession session) {
    try {
      return applications.firstWhere(
        (app) => app.companyId == session.companyId,
      );
    } catch (e) {
      return null; // No application found for this session
    }
  }
}
