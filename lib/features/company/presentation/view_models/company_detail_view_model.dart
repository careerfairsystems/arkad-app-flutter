import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/errors/app_error.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../student_session/presentation/view_models/student_session_view_model.dart';
import '../../domain/entities/company.dart';
import '../commands/get_company_by_id_command.dart';

/// ViewModel for managing company detail screen state
class CompanyDetailViewModel extends ChangeNotifier {
  CompanyDetailViewModel({required GetCompanyByIdCommand getCompanyByIdCommand})
    : _getCompanyByIdCommand = getCompanyByIdCommand {
    _getCompanyByIdCommand.addListener(_onCommandChanged);
  }

  final GetCompanyByIdCommand _getCompanyByIdCommand;

  // Message state for UI feedback
  String? _message;

  // Command getter
  GetCompanyByIdCommand get getCompanyByIdCommand => _getCompanyByIdCommand;

  // Message getter for UI
  String? get message => _message;

  // State getters
  Company? get company => _getCompanyByIdCommand.result;
  bool get isLoading => _getCompanyByIdCommand.isExecuting;
  bool get hasError => _getCompanyByIdCommand.hasError;
  AppError? get error => _getCompanyByIdCommand.error;
  bool get isInitialized => _getCompanyByIdCommand.result != null;

  /// Load company details by ID
  Future<void> loadCompany(int companyId) async {
    await _getCompanyByIdCommand.getCompanyById(companyId);
  }

  /// Clear any errors
  void clearError() {
    _getCompanyByIdCommand.clearError();
    notifyListeners();
  }

  /// Handle session application request with authentication and timeline validation
  void handleSessionApplication(BuildContext context) {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final studentSessionViewModel = Provider.of<StudentSessionViewModel>(context, listen: false);
    
    // Check authentication status
    if (!authViewModel.isAuthenticated) {
      _showSignInPrompt(context);
      return;
    }

    // Check timeline status
    final timelineStatus = TimelineValidationService.getCurrentStatus();
    
    if (!timelineStatus.canApply) {
      _showTimelineInfo(context, timelineStatus);
      return;
    }

    // Get the current company
    final currentCompany = company;
    if (currentCompany == null) {
      _message = 'Company information not available. Please try again.';
      notifyListeners();
      return;
    }

    // Load student session data for this company and navigate
    _loadStudentSessionAndNavigate(context, currentCompany.id, studentSessionViewModel);
  }

  /// Show authentication prompt for unauthenticated users
  void _showSignInPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Required'),
        content: Text(
          'You need to sign in to apply for ${company?.name ?? 'this company'}\'s student session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/auth/login');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    );
  }

  /// Show timeline information when applications are not open
  void _showTimelineInfo(BuildContext context, TimelineStatus timelineStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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

  /// Load student session data for the company and navigate to application form
  Future<void> _loadStudentSessionAndNavigate(
    BuildContext context,
    int companyId,
    StudentSessionViewModel studentSessionViewModel,
  ) async {
    try {
      // Load student sessions to get the specific session for this company
      await studentSessionViewModel.loadStudentSessions();
      
      // Find the session for this company
      final session = studentSessionViewModel.studentSessions
          .where((s) => s.companyId == companyId)
          .firstOrNull;
      
      if (session == null) {
        _message = 'No student session found for this company.';
        notifyListeners();
        return;
      }

      // Navigate to application form with session data
      if (context.mounted) {
        await context.push(
          '/sessions/application-form/$companyId',
          extra: session,
        );
      }
    } catch (e) {
      _message = 'Failed to load student session information. Please try again.';
      notifyListeners();
    }
  }

  /// Clear message after UI has consumed it (call from UI)
  void clearMessage() {
    if (_message != null) {
      _message = null;
      notifyListeners();
    }
  }

  /// Listen to command state changes
  void _onCommandChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _getCompanyByIdCommand.removeListener(_onCommandChanged);
    super.dispose();
  }
}
