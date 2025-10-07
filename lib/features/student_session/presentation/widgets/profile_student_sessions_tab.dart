import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/infrastructure/services/timezone_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/async_state_builder.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/student_session_application.dart';
import '../view_models/student_session_view_model.dart';

class ProfileStudentSessionsTab extends StatefulWidget {
  const ProfileStudentSessionsTab({super.key});

  @override
  State<ProfileStudentSessionsTab> createState() =>
      _ProfileStudentSessionsTabState();
}

class _ProfileStudentSessionsTabState extends State<ProfileStudentSessionsTab> {
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _initializeData();
    }
  }

  void _initializeData() {
    final viewModel = Provider.of<StudentSessionViewModel>(
      context,
      listen: false,
    );
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Only load if authenticated and not already executing
    if (authViewModel.isAuthenticated &&
        !authViewModel.isInitializing &&
        !viewModel.getMyApplicationsWithBookingStateCommand.isExecuting) {
      // Defer reset() call to avoid setState during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        viewModel.getMyApplicationsWithBookingStateCommand.reset();
        viewModel.loadMyApplicationsWithBookingState();
      });

      // Only set hasInitialized to true after actually starting the load
      _hasInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentSessionViewModel, AuthViewModel>(
      builder: (context, viewModel, authViewModel, child) {
        return _buildConsolidatedView(context, viewModel);
      },
    );
  }

  /// Group applications with booking state by status and sort within each group
  Map<ApplicationStatus, List<StudentSessionApplicationWithBookingState>>
  _groupApplicationsWithBookingStateByStatus(
    List<StudentSessionApplicationWithBookingState> applications,
  ) {
    final groups =
        <ApplicationStatus, List<StudentSessionApplicationWithBookingState>>{
          ApplicationStatus.accepted: [],
          ApplicationStatus.pending: [],
          ApplicationStatus.rejected: [],
        };

    for (final app in applications) {
      groups[app.application.status]?.add(app);
    }

    // Sort within each group by submission date (newest first)
    for (final statusGroup in groups.values) {
      statusGroup.sort(
        (a, b) => (b.application.createdAt ?? TimezoneService.stockholmNow())
            .compareTo(
              a.application.createdAt ?? TimezoneService.stockholmNow(),
            ),
      );
    }

    return groups;
  }

  /// Build the consolidated view with all applications in sections
  Widget _buildConsolidatedView(
    BuildContext context,
    StudentSessionViewModel viewModel,
  ) {
    final command = viewModel.getMyApplicationsWithBookingStateCommand;

    return AsyncStateBuilder<List<StudentSessionApplicationWithBookingState>>(
      command: command,
      builder: (context, applications) {
        final groupedApplications = _groupApplicationsWithBookingStateByStatus(
          applications,
        );
        return _buildApplicationsList(context, viewModel, groupedApplications);
      },
      loadingBuilder: (context) => const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading your applications...'),
                ],
              ),
            ),
          ),
        ],
      ),
      errorBuilder: (context, error) => CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: ArkadColors.lightRed,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load applications',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.userMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => command.execute(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsList(
    BuildContext context,
    StudentSessionViewModel viewModel,
    Map<ApplicationStatus, List<StudentSessionApplicationWithBookingState>>
    groupedApplications,
  ) {
    final totalApplications = groupedApplications.values
        .expand((apps) => apps)
        .length;

    return RefreshIndicator(
      onRefresh: () => viewModel.loadMyApplicationsWithBookingState(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          // Always show all sections for consistent structure
          _buildStatusSection(
            context,
            title: 'ACCEPTED APPLICATIONS',
            color: ArkadColors.arkadGreen,
            applications: groupedApplications[ApplicationStatus.accepted]!,
            showActions: true,
          ),

          const SizedBox(height: 24),

          _buildStatusSection(
            context,
            title: 'PENDING APPLICATIONS',
            color: ArkadColors.arkadOrange,
            applications: groupedApplications[ApplicationStatus.pending]!,
            showActions: false,
          ),

          const SizedBox(height: 24),

          _buildStatusSection(
            context,
            title: 'REJECTED APPLICATIONS',
            color: ArkadColors.lightRed,
            applications: groupedApplications[ApplicationStatus.rejected]!,
            showActions: false,
          ),

          // Show get started section only when no applications exist
          if (totalApplications == 0) ...[
            const SizedBox(height: 32),
            _buildGetStartedSection(context),
          ],
        ],
      ),
    );
  }

  /// Build a status section with header and applications
  Widget _buildStatusSection(
    BuildContext context, {
    required String title,
    required Color color,
    required List<StudentSessionApplicationWithBookingState> applications,
    required bool showActions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header - clean professional design
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '$title (${applications.length})',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Applications list with consistent container styling
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(8),
            ),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: applications.isEmpty
              ? _buildEmptySection(context, title.split(' ')[0])
              : Column(
                  children: applications
                      .map(
                        (app) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildUnifiedApplicationCard(
                            context,
                            app,
                            showActions: showActions,
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  /// Build empty state for a section
  Widget _buildEmptySection(BuildContext context, String sectionType) {
    String message;

    switch (sectionType.toLowerCase()) {
      case 'accepted':
        message = 'No accepted applications yet';
      case 'pending':
        message = 'No pending applications';
      case 'rejected':
        message = 'No rejected applications';
      default:
        message = 'No applications in this section';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// Build get started section when no applications exist
  Widget _buildGetStartedSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Get Started',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Apply to companies in the Student Sessions tab to see your applications here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build unified application card with conditional actions based on status
  Widget _buildUnifiedApplicationCard(
    BuildContext context,
    StudentSessionApplicationWithBookingState applicationWithBookingState, {
    required bool showActions,
  }) {
    final application = applicationWithBookingState.application;
    final status = application.status;

    final (statusColor, statusText) = switch (status) {
      ApplicationStatus.pending => (ArkadColors.arkadOrange, 'Under Review'),
      ApplicationStatus.accepted => (
        ArkadColors.arkadGreen,
        'You were accepted!',
      ),
      ApplicationStatus.rejected => (ArkadColors.lightRed, 'Not Selected'),
    };

    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company header with status
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.companyName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        statusText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status.displayName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            // Motivation text preview (if exists and not too long)
            if (application.motivationText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Motivation:',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                application.motivationText,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Action buttons (only for accepted applications when showActions is true)
            if (showActions &&
                application.status == ApplicationStatus.accepted) ...[
              const SizedBox(height: 16),
              _buildBookingActionButtons(context, applicationWithBookingState),
            ],

            // Submission info for non-accepted applications
            if (application.status != ApplicationStatus.accepted &&
                application.createdAt != null) ...[
              const SizedBox(height: 12),
              _buildSubmissionInfo(context, application),
            ],
          ],
        ),
      ),
    );
  }

  /// Build submission timestamp info
  Widget _buildSubmissionInfo(
    BuildContext context,
    StudentSessionApplication application,
  ) {
    if (application.createdAt == null) return const SizedBox.shrink();

    final submittedTime = application.createdAt!;
    final difference = TimezoneService.differenceFromNow(submittedTime);

    String timeAgo;
    // Since differenceFromNow returns negative duration for past dates
    final absDifference = difference.abs();
    if (absDifference.inDays > 0) {
      timeAgo = '${absDifference.inDays} days ago';
    } else if (absDifference.inHours > 0) {
      timeAgo = '${absDifference.inHours} hours ago';
    } else if (absDifference.inMinutes > 0) {
      timeAgo = '${absDifference.inMinutes} minutes ago';
    } else {
      timeAgo = 'Just now';
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule_rounded,
            size: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Text(
            'Submitted $timeAgo',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingActionButtons(
    BuildContext context,
    StudentSessionApplicationWithBookingState applicationWithBookingState,
  ) {
    final application = applicationWithBookingState.application;

    // Show booking actions based on application status - backend controls availability
    if (application.status != ApplicationStatus.accepted) {
      // Show disabled button for non-accepted applications
      final buttonText = switch (application.status) {
        ApplicationStatus.pending => 'Awaiting Acceptance',
        ApplicationStatus.rejected => 'Not Accepted',
        ApplicationStatus.accepted => 'Ready to Book', // Won't reach here
      };

      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.schedule_rounded, size: 18),
              label: Text(buttonText),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      );
    }

    // For accepted applications, use timeline validation to determine button state
    return _buildTimelineAwareBookingButton(
      context,
      applicationWithBookingState,
    );
  }

  /// Build timeline-aware booking button for accepted applications
  Widget _buildTimelineAwareBookingButton(
    BuildContext context,
    StudentSessionApplicationWithBookingState applicationWithBookingState,
  ) {
    final application = applicationWithBookingState.application;
    final hasBooking = applicationWithBookingState.hasBooking;

    // Basic booking logic without full session timeline validation
    // This is a simplified approach since we don't have session data in this context
    // Individual timeslot deadlines will be checked in the booking screen
    String buttonText = hasBooking ? 'Manage Booking' : 'Book Timeslot';
    IconData buttonIcon = hasBooking
        ? Icons.edit_calendar_rounded
        : Icons.schedule_rounded;

    // For accepted applications, booking is generally available
    // Individual timeslot deadlines will be checked in the booking screen

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/sessions/book/${application.companyId}');
                },
                icon: Icon(buttonIcon, size: 18),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArkadColors.arkadTurkos,
                  foregroundColor: ArkadColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
