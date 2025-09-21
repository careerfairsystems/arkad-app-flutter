import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/errors/student_session_errors.dart';
import '../../../../shared/infrastructure/services/file_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_form_field.dart';
import '../../../../shared/services/timeline_validation_service.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../profile/domain/entities/programme.dart';
import '../../domain/entities/student_session.dart';
import '../view_models/student_session_view_model.dart';

class StudentSessionApplicationFormScreen extends StatefulWidget {
  final String companyId;
  final StudentSession? session;

  const StudentSessionApplicationFormScreen({
    super.key,
    required this.companyId,
    this.session,
  });

  @override
  State<StudentSessionApplicationFormScreen> createState() =>
      _StudentSessionApplicationFormScreenState();
}

class _StudentSessionApplicationFormScreenState
    extends State<StudentSessionApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _motivationController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _masterTitleController = TextEditingController();

  StudentSession? _session;
  int _motivationWordCount = 0;
  
  // Mandatory form fields
  File? _selectedCV;
  Programme? _selectedProgramme;
  int? _studyYear;
  
  // Message display tracking is now handled by ViewModel flags
  

  @override
  void initState() {
    super.initState();
    _motivationController.addListener(_updateWordCount);
    
    // Use the passed session data directly
    _session = widget.session;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      final authViewModel = Provider.of<AuthViewModel>(
        context,
        listen: false,
      );

      // Reset command state and clear any previous messages
      viewModel.applyForSessionCommand.reset();
      viewModel.clearAllMessages();
      
      // If no session was passed, navigate back
      if (_session == null) {
        context.pop();
        return;
      }
      
      // Prepopulate form with user profile data (except motivation text)
      _prepopulateFormWithUserData(authViewModel.currentUser);
    });
  }

  @override
  void dispose() {
    _motivationController.dispose();
    _linkedinController.dispose();
    _masterTitleController.dispose();
    super.dispose();
  }

  void _updateWordCount() {
    final text = _motivationController.text.trim();
    if (text.isEmpty) {
      setState(() => _motivationWordCount = 0);
    } else {
      final words = text.split(RegExp(r'\s+'));
      setState(() => _motivationWordCount = words.length);
    }
  }

  /// Prepopulate form fields with user profile data (except motivation text)
  void _prepopulateFormWithUserData(User? user) {
    if (user == null) return;

    setState(() {
      // Convert string programme to Programme enum
      if (user.programme != null) {
        _selectedProgramme = ProgrammeUtils.labelToProgramme(user.programme!);
      }
      
      // Set study year
      _studyYear = user.studyYear;
      
      // Set master's title
      if (user.masterTitle?.isNotEmpty == true) {
        _masterTitleController.text = user.masterTitle!;
      }
      
      // Set LinkedIn profile
      if (user.linkedin?.isNotEmpty == true) {
        _linkedinController.text = user.linkedin!;
      }
      
      // Note: Motivation text is intentionally not prepopulated as it should be unique per application
      // Note: CV is not prepopulated as users may want to upload a different CV for this application
    });
  }

  bool _validateMandatoryFields() {
    // Validate CV upload
    if (_selectedCV == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CV upload is required for student session applications'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return false;
    }

    // Validate programme selection
    if (_selectedProgramme == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Programme selection is required'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return false;
    }

    // Validate study year
    if (_studyYear == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Study year selection is required'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return false;
    }

    // Validate master title
    if (_masterTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Master\'s title is required'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate mandatory fields
    if (!_validateMandatoryFields()) return;

    // Validate timeline before submission
    try {
      TimelineValidationService.validateApplicationAllowed();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return;
    }

    final viewModel = Provider.of<StudentSessionViewModel>(
      context,
      listen: false,
    );

    // CV upload is now integrated with application submission
    await viewModel.applyForSession(
      companyId: int.parse(widget.companyId),
      motivationText: _motivationController.text.trim(),
      programme: ProgrammeUtils.programmeToLabel(_selectedProgramme),
      linkedin:
          _linkedinController.text.trim().isEmpty
              ? null
              : _linkedinController.text.trim(),
      masterTitle: _masterTitleController.text.trim(),
      studyYear: _studyYear,
      cvFilePath: _selectedCV?.path,
    );
  }
  
  /// Retry CV upload for a failed application
  Future<void> _retryCVUpload(StudentSessionViewModel viewModel) async {
    if (_selectedCV == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a CV file first'),
          backgroundColor: ArkadColors.lightRed,
        ),
      );
      return;
    }
    
    // The ViewModel will handle success/error message display through flags
    await viewModel.retryCVUpload(
      companyId: int.parse(widget.companyId),
      filePath: _selectedCV!.path,
    );
    
    // Success and error messages are now handled by the Consumer logic above
  }

  @override
  Widget build(BuildContext context) {
    // If no session, show loading (will navigate back in initState)
    if (_session == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Apply for Session')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Session'), elevation: 2),
      body: Consumer<StudentSessionViewModel>(
        builder: (context, viewModel, child) {
          // Handle success messages
          if (viewModel.showSuccessMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(viewModel.successMessage ?? 'Success!'),
                    backgroundColor: ArkadColors.arkadGreen,
                  ),
                );
                
                // Clear the message flag
                viewModel.clearSuccessMessage();
                
                // Navigate back after a short delay to ensure message is visible
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (mounted && context.mounted && Navigator.canPop(context)) {
                    context.pop();
                  }
                });
              }
            });
          }
          
          // Handle error messages
          if (viewModel.showErrorMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                final errorMessage = viewModel.errorMessage ?? 'An error occurred. Please try again.';
                final showRetryOption = errorMessage.contains('CV') && _selectedCV != null;
                
                // Handle specific 401 authentication errors
                if (errorMessage.contains('session has expired') || errorMessage.contains('Unauthorized')) {
                  // Clear authentication and redirect to login
                  final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
                  authViewModel.signOut();
                  
                  // Navigate to login after showing error
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted && context.mounted) {
                      context.go('/auth/login');
                    }
                  });
                }
                
                // Show error message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                    backgroundColor: ArkadColors.lightRed,
                    duration: showRetryOption ? const Duration(seconds: 6) : const Duration(seconds: 4),
                    action: showRetryOption ? SnackBarAction(
                      label: 'Retry CV',
                      textColor: Colors.white,
                      onPressed: () => _retryCVUpload(viewModel),
                    ) : null,
                  ),
                );
                
                // Clear the message flag
                viewModel.clearErrorMessage();
              }
            });
          }

          return _buildForm(viewModel);
        },
      ),
    );
  }

  Widget _buildForm(StudentSessionViewModel viewModel) {
    final isSubmitting = viewModel.applyForSessionCommand.isExecuting;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionInfo(),
            const SizedBox(height: 32),
            _buildTimelineWarning(),
            const SizedBox(height: 32),
            
            // Motivation Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMotivationField(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Academic Information Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildMandatoryFields(),
              ),
            ),
            const SizedBox(height: 24),
            
            // Optional Information Section
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Information (Optional)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildOptionalFields(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSubmitButton(isSubmitting),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionInfo() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ArkadColors.arkadNavy,
            ArkadColors.arkadTurkos,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session!.companyName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Student Session Application',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_session!.description != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _session!.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineWarning() {
    final status = TimelineValidationService.getCurrentStatus();

    if (!status.canApply) {
      Color statusColor;
      IconData statusIcon;

      switch (status.phase) {
        case StudentSessionPhase.beforeApplication:
          statusColor = Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.7);
          statusIcon = Icons.schedule_rounded;
        case StudentSessionPhase.applicationClosed:
        case StudentSessionPhase.beforeBooking:
        case StudentSessionPhase.bookingClosed:
        case StudentSessionPhase.sessionComplete:
          statusColor = ArkadColors.lightRed;
          statusIcon = Icons.warning_rounded;
        default:
          return const SizedBox.shrink();
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
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                status.reason,
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

    return const SizedBox.shrink();
  }

  Widget _buildMotivationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivation *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Explain why you want to participate in this student session (max 300 words)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _motivationController,
          decoration: const InputDecoration(
            labelText: 'Your motivation',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          maxLines: 8,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Motivation is required';
            }
            if (_motivationWordCount > 300) {
              return 'Motivation must be 300 words or less';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_motivationWordCount / 300 words',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color:
                  _motivationWordCount > 300
                      ? ArkadColors.lightRed
                      : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: _motivationWordCount > 300 ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFields() {
    return ArkadFormField(
      controller: _linkedinController,
      labelText: 'LinkedIn Profile (Optional)',
      hintText: 'https://linkedin.com/in/yourprofile or just your username',
    );
  }


  Widget _buildMandatoryFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Academic Information *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        // Programme Dropdown
        DropdownButtonFormField<Programme>(
          decoration: const InputDecoration(
            labelText: 'Programme *',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: _selectedProgramme,
          hint: const Text('Select your programme'),
          validator: (value) {
            if (value == null) return 'Programme is required';
            return null;
          },
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down),
          menuMaxHeight: 350,
          items: availableProgrammes.map((program) {
            return DropdownMenuItem<Programme>(
              value: program.value,
              child: Text(
                program.label,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (Programme? newValue) {
            setState(() {
              _selectedProgramme = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Study Year Dropdown
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Study Year *',
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
          value: _studyYear,
          hint: const Text('Select your study year'),
          validator: (value) {
            if (value == null) return 'Study year is required';
            return null;
          },
          items: [1, 2, 3, 4, 5].map((year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text('Year $year'),
            );
          }).toList(),
          onChanged: (int? newValue) {
            setState(() {
              _studyYear = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        
        // Master Title Field
        ArkadFormField(
          controller: _masterTitleController,
          labelText: 'Master\'s Title *',
          hintText: 'Your master\'s programme title',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Master\'s title is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        
        // CV Upload Section
        Text(
          'CV / Resume *',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedCV == null ? ArkadColors.lightRed : ArkadColors.arkadGreen,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _selectedCV == null 
                ? ArkadColors.lightRed.withValues(alpha: 0.05)
                : ArkadColors.arkadGreen.withValues(alpha: 0.05),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _selectedCV != null ? Icons.check_circle : Icons.upload_file,
                    color: _selectedCV != null ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedCV != null
                              ? 'CV Selected: ${_selectedCV!.path.split('/').last}'
                              : 'CV Required - No file selected',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _selectedCV != null ? ArkadColors.arkadGreen : ArkadColors.lightRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF format only, max 10MB',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _pickCV,
                      icon: const Icon(Icons.attach_file, color: ArkadColors.white),
                      label: Text(_selectedCV != null ? 'Change CV' : 'Select CV File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArkadColors.arkadTurkos,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  if (_selectedCV != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedCV = null),
                      icon: const Icon(Icons.delete, color: ArkadColors.lightRed),
                      label: const Text(
                        'Remove',
                        style: TextStyle(color: ArkadColors.lightRed),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickCV() async {
    final fileService = serviceLocator<FileService>();
    final File? cv = await fileService.pickCVFile(context: context);

    if (cv != null) {
      setState(() {
        _selectedCV = cv;
      });
    }
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    final status = TimelineValidationService.getCurrentStatus();
    final hasAllMandatoryFields = _selectedCV != null && 
                                 _selectedProgramme != null && 
                                 _studyYear != null && 
                                 _masterTitleController.text.trim().isNotEmpty &&
                                 _motivationController.text.trim().isNotEmpty &&
                                 _motivationWordCount <= 300;
    
    final canSubmit = status.canApply && !isSubmitting && hasAllMandatoryFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasAllMandatoryFields) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ArkadColors.lightRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: ArkadColors.lightRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_rounded, color: ArkadColors.lightRed, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please complete all required fields: motivation, programme, study year, master title, and CV upload.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: ArkadColors.lightRed,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: canSubmit ? _submitApplication : null,
            style: FilledButton.styleFrom(
              backgroundColor: canSubmit ? ArkadColors.arkadTurkos : ArkadColors.gray,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child:
                isSubmitting
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : Text(
                      _selectedCV != null 
                          ? 'Submit Application with CV'
                          : 'Submit Application',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
          ),
        ),
      ],
    );
  }
}
