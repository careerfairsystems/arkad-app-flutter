import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/entities/student_session_application.dart';
import '../view_models/student_session_view_model.dart';
import '../widgets/student_session_card.dart';

class StudentSessionsScreen extends StatefulWidget {
  const StudentSessionsScreen({super.key});

  @override
  State<StudentSessionsScreen> createState() => _StudentSessionsScreenState();
}

class _StudentSessionsScreenState extends State<StudentSessionsScreen> {
  late final TextEditingController _searchController;
  StreamSubscription? _logoutSubscription;
  StreamSubscription? _authSubscription;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _subscribeToAuthEvents();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      _resetCommandStates(viewModel);
      _loadInitialData(viewModel);
    });
  }

  void _subscribeToAuthEvents() {
    // Listen for logout events
    _logoutSubscription = AppEvents.on<UserLoggedOutEvent>().listen((_) {
      _clearUIState();
    });
    
    // Listen for login events to refresh data
    _authSubscription = AppEvents.on<AuthSessionChangedEvent>().listen((_) {
      _refreshDataAfterAuth();
    });
  }

  void _refreshDataAfterAuth() {
    if (mounted) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      // Refresh both sessions and applications to get updated user status
      _loadInitialData(viewModel);
    }
  }

  void _clearUIState() {
    if (mounted) {
      _searchController.clear();
    }
  }

  void _resetCommandStates(StudentSessionViewModel viewModel) {
    viewModel.getStudentSessionsCommand.reset();
    viewModel.getMyApplicationsCommand.reset();
  }

  Future<void> _loadInitialData(StudentSessionViewModel viewModel) async {
    await Future.wait([
      viewModel.loadStudentSessions(),
      viewModel.loadMyApplications(),
    ]);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _logoutSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentSessionViewModel>(
      builder: (context, viewModel, child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Student Sessions'), elevation: 2),
          body: Column(
            children: [
              _buildSearchBar(viewModel),
              _buildTimelineInfo(context),
              Expanded(child: _buildSessionsList(viewModel)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchBar(StudentSessionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search companies...',
          prefixIcon: const Icon(Icons.search_rounded),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: ArkadColors.arkadTurkos, width: 2),
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
          suffixIcon:
              _searchController.text.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchController.clear();
                      viewModel.clearSearch();
                    },
                  )
                  : null,
        ),
        onChanged: viewModel.searchStudentSessions,
      ),
    );
  }

  Widget _buildTimelineInfo(BuildContext context) {
    final status = TimelineValidationService.getCurrentStatus();

    Color statusColor;
    IconData statusIcon;

    if (status.canApply) {
      statusColor = ArkadColors.arkadGreen;
      statusIcon = Icons.check_circle_rounded;
    } else if (status.canBook) {
      statusColor = ArkadColors.arkadTurkos;
      statusIcon = Icons.event_available_rounded;
    } else {
      statusColor = Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.7);
      statusIcon = Icons.schedule_rounded;
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              status.reason,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(StudentSessionViewModel viewModel) {
    final command = viewModel.getStudentSessionsCommand;

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
              'Failed to load student sessions',
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
              onPressed: () => _loadInitialData(viewModel),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final sessions = viewModel.filteredStudentSessions;
    final applications = viewModel.myApplications;

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.business_center_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No student sessions available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Check back during the application period',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(viewModel),
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final application =
              applications
                  .where((app) => app.companyId == session.companyId)
                  .firstOrNull;

          return StudentSessionCard(
            session: session,
            application: application,
            onTap: () => _onSessionTap(session),
            onApply: () => _onApplyForSession(session),
            onViewTimeslots: () => _onViewTimeslots(session),
          );
        },
      ),
    );
  }

  void _onSessionTap(StudentSession session) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final sessionViewModel = Provider.of<StudentSessionViewModel>(
      context,
      listen: false,
    );

    // Check authentication status
    if (!authViewModel.isAuthenticated) {
      _showSignInPrompt(session);
      return;
    }

    // Check timeline status
    final timelineStatus = TimelineValidationService.getCurrentStatus();

    // Check if user has already applied
    final existingApplication =
        sessionViewModel.myApplications
            .where((app) => app.companyId == session.companyId)
            .firstOrNull;

    if (timelineStatus.canApply && existingApplication == null) {
      // Can apply - navigate to application form
      context.push(
        '/sessions/application-form/${session.companyId}',
        extra: session,
      );
    } else if (existingApplication != null) {
      // Already applied - show status or navigate to profile
      _showApplicationStatus(session, existingApplication);
    } else {
      // Outside application period - show timeline info
      _showTimelineInfo(timelineStatus);
    }
  }

  void _onApplyForSession(StudentSession session) {
    // Use the same authentication and validation logic as card tap
    _onSessionTap(session);
  }

  void _onViewTimeslots(StudentSession session) {
    // Navigate to timeslot selection
    context.push('/sessions/apply/${session.companyId}');
  }

  void _showSignInPrompt(StudentSession session) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign In Required'),
            content: Text(
              'You need to sign in to apply for ${session.companyName}\'s student session.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Navigate to login with return path
                  context.push('/auth/login');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: ArkadColors.arkadTurkos,
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
    );
  }

  void _showApplicationStatus(
    StudentSession session,
    StudentSessionApplication application,
  ) {
    final status = application.status;
    String title;
    String message;
    List<Widget> actions;

    switch (status) {
      case ApplicationStatus.pending:
        title = 'Application Submitted';
        message =
            'Your application to ${session.companyName} is under review. '
            'You can check the status in your Profile > Student Sessions tab.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to profile student sessions tab
              context.push('/profile');
            },
            style: FilledButton.styleFrom(
              backgroundColor: ArkadColors.arkadTurkos,
            ),
            child: const Text('View in Profile'),
          ),
        ];
      case ApplicationStatus.accepted:
        title = 'Application Accepted! 🎉';
        message =
            'Congratulations! ${session.companyName} has accepted your application. '
            'You can now book a timeslot when the booking period opens.';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/profile');
            },
            style: FilledButton.styleFrom(
              backgroundColor: ArkadColors.arkadGreen,
            ),
            child: const Text('View Details'),
          ),
        ];
      case ApplicationStatus.rejected:
        title = 'Application Not Selected';
        message =
            'Unfortunately, ${session.companyName} did not select your application this time. '
            'Keep trying with other companies!';
        actions = [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ];
    }

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: actions,
          ),
    );
  }

  void _showTimelineInfo(TimelineStatus timelineStatus) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Student Session Information'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(timelineStatus.reason),
                const SizedBox(height: 16),
                if (timelineStatus.timelineInfo.isNotEmpty) ...[
                  const Text(
                    'Timeline:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timelineStatus.timelineInfo,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
