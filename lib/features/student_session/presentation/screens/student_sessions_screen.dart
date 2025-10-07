import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/events/app_events.dart';
import '../../../../shared/events/auth_events.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/services/timeline_validation_service.dart';
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
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Only load applications if user is authenticated
      // For public users, only load student sessions
      if (authViewModel.isAuthenticated) {
        _loadInitialData(viewModel);
      } else {
        // Public view - only load student sessions
        viewModel.loadStudentSessions();
      }
    }
  }

  void _clearUIState() {
    if (mounted) {
      _searchController.clear();
    }
  }

  void _resetCommandStates(StudentSessionViewModel viewModel) {
    viewModel.getStudentSessionsCommand.reset();
    viewModel.getMyApplicationsWithBookingStateCommand.reset();
  }

  Future<void> _loadInitialData(StudentSessionViewModel viewModel) async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (authViewModel.isAuthenticated) {
      // Authenticated users: load sessions and applications
      await Future.wait([
        viewModel.loadStudentSessions(),
        viewModel.loadMyApplicationsWithBookingState(),
      ]);
    } else {
      // Public users: only load sessions
      await viewModel.loadStudentSessions();
    }
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
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sessions'),
              elevation: 2,
              bottom: const TabBar(
                indicatorColor: ArkadColors.arkadTurkos,
                labelColor: ArkadColors.arkadTurkos,
                unselectedLabelColor: ArkadColors.lightGray,
                tabs: [
                  Tab(text: 'Student Sessions'),
                  Tab(text: 'Company Visits'),
                ],
              ),
            ),
            body: Column(
              children: [
                _buildSearchBar(viewModel),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildSessionsList(
                        viewModel,
                        viewModel.filteredRegularSessions,
                      ),
                      _buildSessionsList(
                        viewModel,
                        viewModel.filteredCompanyEvents,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
            borderSide: const BorderSide(
              color: ArkadColors.arkadTurkos,
              width: 2,
            ),
          ),
          filled: true,
          fillColor: Theme.of(
            context,
          ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
          suffixIcon: _searchController.text.isNotEmpty
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

  Widget _buildSessionsList(
    StudentSessionViewModel viewModel,
    List<StudentSession> sessions,
  ) {
    final command = viewModel.getStudentSessionsCommand;

    if (command.isExecuting) {
      return const CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading student sessions...'),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (command.hasError) {
      return CustomScrollView(
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
            ),
          ),
        ],
      );
    }

    final applicationsWithBookingState =
        viewModel.myApplicationsWithBookingState;

    if (sessions.isEmpty) {
      return CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            child: Center(
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
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadInitialData(viewModel),
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: sessions.length,
        itemBuilder: (context, index) {
          final session = sessions[index];
          final applicationWithBookingState = applicationsWithBookingState
              .where(
                (appWithState) =>
                    appWithState.application.companyId == session.companyId,
              )
              .firstOrNull;

          return StudentSessionCard(
            session: session,
            application: applicationWithBookingState?.application,
            applicationWithBookingState: applicationWithBookingState,
            onApply: () => _onApplyForSession(session),
            onViewTimeslots: () => _onViewTimeslots(session),
          );
        },
      ),
    );
  }

  void _onApplyForSession(StudentSession session) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    // Check authentication status
    if (!authViewModel.isAuthenticated) {
      _showSignInPrompt(session);
      return;
    }

    // Check timeline validation before allowing navigation
    const timelineService = TimelineValidationService.instance;
    if (!timelineService.canNavigateToApplication(session)) {
      _showTimelineRestrictionMessage(session);
      return;
    }

    // Navigate to application form
    context.push(
      '/sessions/application-form/${session.companyId}',
      extra: session,
    );
  }

  void _onViewTimeslots(StudentSession session) {
    // Navigate to booking flow for accepted applications
    context.push('/sessions/book/${session.companyId}');
  }

  void _showSignInPrompt(StudentSession session) {
    // Capture the original context before showing dialog
    final originalContext = context;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text(
          'You need to sign in to apply for ${session.companyName}\'s student session.',
        ),
        actions: [
          TextButton(
            onPressed: () => dialogContext.pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              dialogContext.pop();
              // Navigate to login tab (branch index 5) using original context
              StatefulNavigationShell.of(originalContext).goBranch(5);
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

  void _showTimelineRestrictionMessage(StudentSession session) {
    const timelineService = TimelineValidationService.instance;
    final timelineMessage =
        timelineService.getTimelineMessage(session) ??
        'Applications are currently not available for this session.';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Application Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Applications for ${session.companyName}\'s student session are currently not available.',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ArkadColors.lightGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: ArkadColors.lightGray.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule_rounded,
                    size: 20,
                    color: ArkadColors.lightGray,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      timelineMessage,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => dialogContext.pop(),
            style: FilledButton.styleFrom(
              backgroundColor: ArkadColors.arkadTurkos,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
