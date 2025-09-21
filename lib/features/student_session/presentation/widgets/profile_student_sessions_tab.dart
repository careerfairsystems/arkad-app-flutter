import 'package:flutter/material.dart';
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

class _ProfileStudentSessionsTabState extends State<ProfileStudentSessionsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );

      // Reset command states and load data
      viewModel.getMyApplicationsCommand.reset();
      viewModel.loadMyApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<StudentSessionViewModel, AuthViewModel>(
      builder: (context, viewModel, authViewModel, child) {
        // Auto-reload applications when authentication becomes ready
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (authViewModel.isAuthenticated && 
              !authViewModel.isInitializing &&
              viewModel.myApplications.isEmpty &&
              !viewModel.getMyApplicationsCommand.isExecuting) {
            viewModel.loadMyApplications();
          }
        });

        final applications = viewModel.myApplications;
        final pendingCount =
            applications
                .where((app) => app.status == ApplicationStatus.pending)
                .length;
        final acceptedCount =
            applications
                .where((app) => app.status == ApplicationStatus.accepted)
                .length;

        return Column(
          children: [
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.assignment_turned_in_outlined, size: 18),
                      const SizedBox(width: 6),
                      Text('My Applications ($pendingCount)'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 18),
                      const SizedBox(width: 6),
                      Text('Accepted ($acceptedCount)'),
                    ],
                  ),
                ),
              ],
              labelColor: ArkadColors.arkadTurkos,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              indicatorColor: ArkadColors.arkadTurkos,
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildApplicationsTab(context, viewModel, applications),
                  _buildAcceptedTab(
                    context,
                    viewModel,
                    applications
                        .where(
                          (app) => app.status == ApplicationStatus.accepted,
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildApplicationsTab(
    BuildContext context,
    StudentSessionViewModel viewModel,
    List<StudentSessionApplication> applications,
  ) {
    final command = viewModel.getMyApplicationsCommand;

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

    if (applications.isEmpty) {
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
      onRefresh: () => viewModel.loadMyApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return _buildApplicationCard(context, application);
        },
      ),
    );
  }

  Widget _buildAcceptedTab(
    BuildContext context,
    StudentSessionViewModel viewModel,
    List<StudentSessionApplication> acceptedApplications,
  ) {
    if (acceptedApplications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No Accepted Applications',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'When companies accept your applications, they will appear here',
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
      onRefresh: () => viewModel.loadMyApplications(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: acceptedApplications.length,
        itemBuilder: (context, index) {
          final application = acceptedApplications[index];
          return _buildAcceptedApplicationCard(context, application);
        },
      ),
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    StudentSessionApplication application,
  ) {
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
        statusText = 'Accepted';
      case ApplicationStatus.rejected:
        statusColor = ArkadColors.lightRed;
        statusIcon = Icons.cancel_rounded;
        statusText = 'Not Selected';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: ArkadColors.arkadTurkos.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: ArkadColors.arkadTurkos,
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
          ],
        ),
      ),
    );
  }

  Widget _buildAcceptedApplicationCard(
    BuildContext context,
    StudentSessionApplication application,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: ArkadColors.arkadGreen.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: ArkadColors.arkadGreen,
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
                        'You were accepted!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArkadColors.arkadGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildBookingStatus(context),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Navigate to booking
                      // Note: For now this is commented out since we're focusing on applications
                      // context.push('/sessions/apply/${application.companyId}');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Booking functionality coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.schedule_rounded, size: 18),
                    label: const Text('Book Timeslot'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ArkadColors.arkadTurkos,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingStatus(BuildContext context) {
    final status = TimelineValidationService.checkBookingPeriod();

    String statusText;
    Color statusColor;
    IconData statusIcon;

    switch (status.phase) {
      case StudentSessionPhase.beforeBooking:
      case StudentSessionPhase.applicationClosed:
        statusText = 'Booking opens November 2, 2025 at 17:00';
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusIcon = Icons.schedule_rounded;
      case StudentSessionPhase.bookingOpen:
        statusText = 'Booking is open until November 5, 2025';
        statusColor = ArkadColors.arkadGreen;
        statusIcon = Icons.event_available_rounded;
      default:
        statusText = 'Booking period has ended';
        statusColor = Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.7);
        statusIcon = Icons.event_busy_rounded;
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
}
