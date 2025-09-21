import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/services/timeline_validation_service.dart';
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
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );

      // Reset command states and load data with real booking state
      viewModel.getMyApplicationsCommand.reset();
      viewModel.getMyApplicationsWithBookingStateCommand.reset();
      viewModel.loadMyApplicationsWithBookingState();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentSessionViewModel, AuthViewModel>(
      builder: (context, viewModel, authViewModel, child) {
        // Handle booking/unbooking success/error messages
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (viewModel.showSuccessMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  viewModel.successMessage ??
                      'Operation completed successfully!',
                ),
                backgroundColor: ArkadColors.arkadGreen,
              ),
            );
            viewModel.clearSuccessMessage();
          }

          if (viewModel.showErrorMessage) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  viewModel.errorMessage ??
                      'An error occurred. Please try again.',
                ),
                backgroundColor: ArkadColors.lightRed,
              ),
            );
            viewModel.clearErrorMessage();
          }
        });
        // Auto-reload applications when authentication becomes ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authViewModel.isAuthenticated &&
              !authViewModel.isInitializing &&
              viewModel.myApplicationsWithBookingState.isEmpty &&
              !viewModel.getMyApplicationsWithBookingStateCommand.isExecuting) {
            viewModel.loadMyApplicationsWithBookingState();
          }
        });

        final applicationsWithBookingState = viewModel.myApplicationsWithBookingState;
        final groupedApplications = _groupApplicationsWithBookingStateByStatus(applicationsWithBookingState);

        return _buildConsolidatedView(context, viewModel, groupedApplications);
      },
    );
  }

  /// Group applications with booking state by status and sort within each group
  Map<ApplicationStatus, List<StudentSessionApplicationWithBookingState>>
  _groupApplicationsWithBookingStateByStatus(List<StudentSessionApplicationWithBookingState> applications) {
    final groups = <ApplicationStatus, List<StudentSessionApplicationWithBookingState>>{
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
        (a, b) => (b.application.createdAt ?? DateTime.now()).compareTo(
          a.application.createdAt ?? DateTime.now(),
        ),
      );
    }

    return groups;
  }

  /// Build the consolidated view with all applications in sections
  Widget _buildConsolidatedView(
    BuildContext context,
    StudentSessionViewModel viewModel,
    Map<ApplicationStatus, List<StudentSessionApplicationWithBookingState>> groupedApplications,
  ) {
    final command = viewModel.getMyApplicationsWithBookingStateCommand;

    if (command.isExecuting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (command.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: ArkadColors.lightRed),
            const SizedBox(height: 16),
            Text(
              'Failed to load applications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              command.error?.userMessage ?? 'Please try again',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => viewModel.loadMyApplications(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totalApplications =
        groupedApplications.values.expand((apps) => apps).length;

    if (totalApplications == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Applications Yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Student Sessions tab to apply for companies',
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

    return RefreshIndicator(
      onRefresh: () => viewModel.loadMyApplicationsWithBookingState(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accepted applications section
          _buildStatusSection(
            context,
            title: 'ACCEPTED APPLICATIONS',
            icon: Icons.check_circle_rounded,
            color: ArkadColors.arkadGreen,
            applications: groupedApplications[ApplicationStatus.accepted]!,
            showActions: true,
          ),

          const SizedBox(height: 24),

          // Pending applications section
          _buildStatusSection(
            context,
            title: 'PENDING APPLICATIONS',
            icon: Icons.hourglass_empty_rounded,
            color: Colors.orange,
            applications: groupedApplications[ApplicationStatus.pending]!,
            showActions: false,
          ),

          const SizedBox(height: 24),

          // Rejected applications section (only if there are rejected applications)
          if (groupedApplications[ApplicationStatus.rejected]!.isNotEmpty)
            _buildStatusSection(
              context,
              title: 'REJECTED APPLICATIONS',
              icon: Icons.cancel_rounded,
              color: ArkadColors.lightRed,
              applications: groupedApplications[ApplicationStatus.rejected]!,
              showActions: false,
            ),
        ],
      ),
    );
  }

  /// Build a status section with header and applications
  Widget _buildStatusSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required List<StudentSessionApplicationWithBookingState> applications,
    required bool showActions,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              '$title (${applications.length})',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Applications list
        if (applications.isEmpty)
          _buildEmptySection(context, title.split(' ')[0])
        else
          ...applications.map(
            (app) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildUnifiedApplicationCard(
                context,
                app,
                showActions: showActions,
              ),
            ),
          ),
      ],
    );
  }

  /// Build empty state for a section
  Widget _buildEmptySection(BuildContext context, String sectionType) {
    String message;
    IconData iconData;

    switch (sectionType.toLowerCase()) {
      case 'accepted':
        message = 'No accepted applications yet';
        iconData = Icons.check_circle_outline;
      case 'pending':
        message = 'No pending applications';
        iconData = Icons.hourglass_empty_outlined;
      case 'rejected':
        message = 'No rejected applications';
        iconData = Icons.cancel_outlined;
      default:
        message = 'No applications in this section';
        iconData = Icons.assignment_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            Icon(
              iconData,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
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
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ApplicationStatus.pending:
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        statusText = 'Under Review';
      case ApplicationStatus.accepted:
        statusColor = ArkadColors.arkadGreen;
        statusIcon = Icons.check_circle_rounded;
        statusText = 'You were accepted!';
      case ApplicationStatus.rejected:
        statusColor = ArkadColors.lightRed;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Not Selected';
    }

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
                      Row(
                        children: [
                          Icon(statusIcon, size: 16, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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

            // Status-specific content for accepted applications
            if (application.status == ApplicationStatus.accepted) ...[
              const SizedBox(height: 16),
              _buildApplicationBookingStatus(context, application),
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
    final now = DateTime.now();
    final difference = now.difference(submittedTime);

    String timeAgo;
    if (difference.inDays > 0) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      timeAgo = '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      timeAgo = '${difference.inMinutes} minutes ago';
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

  Widget _buildApplicationBookingStatus(
    BuildContext context,
    StudentSessionApplication application,
  ) {
    // Get current timeline status to show appropriate message
    final status = TimelineValidationService.checkBookingPeriod();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    // Since BookingInfo isn't available from API yet, show timeline-based status
    switch (status.phase) {
      case StudentSessionPhase.bookingOpen:
        statusText = 'Ready to book timeslot';
        statusColor = ArkadColors.arkadGreen;
        statusIcon = Icons.event_available_rounded;
      case StudentSessionPhase.beforeBooking:
      case StudentSessionPhase.applicationClosed:
        statusText =
            status.reason; // Use the timeline service's formatted message
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusIcon = Icons.schedule_rounded;
      case StudentSessionPhase.bookingClosed:
        statusText = 'Booking period ended';
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusIcon = Icons.event_busy_rounded;
      default:
        statusText = 'Booking not available';
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              statusText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
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
    final hasBooking = applicationWithBookingState.hasBooking;
    
    final status = TimelineValidationService.checkBookingPeriod();
    final isBookingOpen = status.phase == StudentSessionPhase.bookingOpen;

    // Show booking status and actions based on real API data
    if (!isBookingOpen) {
      // Show disabled button with timeline-appropriate message
      String buttonText;
      switch (status.phase) {
        case StudentSessionPhase.beforeBooking:
        case StudentSessionPhase.applicationClosed:
          buttonText = 'Booking Opens Later';
        case StudentSessionPhase.bookingClosed:
          buttonText = 'Booking Ended';
        default:
          buttonText = 'Booking Not Available';
      }

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

    // Booking is open - show single manage booking button
    String buttonText = hasBooking ? 'Manage Booking' : 'Book Timeslot';
    IconData buttonIcon = hasBooking ? Icons.edit_calendar_rounded : Icons.schedule_rounded;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              context.push('/sessions/book/${application.companyId}');
            },
            icon: Icon(buttonIcon, size: 18),
            label: Text(buttonText),
            style: OutlinedButton.styleFrom(
              foregroundColor: ArkadColors.arkadTurkos,
            ),
          ),
        ),
      ],
    );
  }
}
