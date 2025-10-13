import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/domain/validation/validation_service.dart';
import '../../../../shared/infrastructure/services/file_service.dart';
import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../../../shared/presentation/widgets/arkad_form_field.dart';
import '../../../../shared/presentation/widgets/optimized_image.dart';
import '../../../auth/presentation/view_models/auth_view_model.dart';
import '../../../profile/domain/entities/profile.dart';
import '../../../profile/domain/entities/programme.dart';
import '../../../profile/presentation/view_models/profile_view_model.dart';
import '../../domain/entities/student_session.dart';
import '../../domain/services/student_session_form_config_service.dart';
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
  StudentSessionFormConfigService? _formConfig;
  int _motivationWordCount = 0;

  // Form fields - requirements now determined dynamically
  PlatformFile? _selectedCV;
  Programme? _selectedProgramme;
  int? _studyYear;

  // CV validation state tracking
  bool _cvFieldTouched = false;

  // Message handling state to prevent duplicates and setState during build
  bool _hasHandledApplicationSuccess = false;
  bool _hasHandledApplicationError = false;

  @override
  void initState() {
    super.initState();
    _motivationController.addListener(_updateWordCount);

    // Use the passed session data directly and create form configuration
    _session = widget.session;
    if (_session != null) {
      _formConfig = StudentSessionFormConfigService(
        fieldConfigurations: _session!.fieldConfigurations,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final viewModel = Provider.of<StudentSessionViewModel>(
        context,
        listen: false,
      );
      final profileViewModel = Provider.of<ProfileViewModel>(
        context,
        listen: false,
      );

      // Reset command state
      viewModel.applyForSessionCommand.reset();

      // If no session was passed, navigate back
      if (_session == null) {
        context.pop();
        return;
      }

      // Prepopulate form with user profile data (except motivation text)
      _prepopulateFormWithUserData(profileViewModel.currentProfile);
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
  /// Only prepopulates visible fields to respect form configuration
  void _prepopulateFormWithUserData(Profile? profile) {
    if (profile == null || _formConfig == null) return;

    setState(() {
      // Set programme (only if field is visible)
      if (_formConfig!.shouldShowField('programme') &&
          profile.programme != null) {
        _selectedProgramme = profile.programme;
      }

      // Set study year (only if field is visible and valid)
      if (_formConfig!.shouldShowField('studyYear')) {
        // Only set study year if it's within valid range [1-5]
        _studyYear =
            (profile.studyYear != null &&
                profile.studyYear! >= 1 &&
                profile.studyYear! <= 5)
            ? profile.studyYear
            : null;
      }

      // Set master's title (only if field is visible)
      if (_formConfig!.shouldShowField('masterTitle') &&
          profile.masterTitle?.isNotEmpty == true) {
        _masterTitleController.text = profile.masterTitle!;
      }

      // Set LinkedIn profile (only if field is visible)
      if (_formConfig!.shouldShowField('linkedin') &&
          profile.linkedin?.isNotEmpty == true) {
        _linkedinController.text = profile.linkedin!;
      }

      // Note: Motivation text is intentionally not prepopulated as it should be unique per application
      // Note: CV is not prepopulated as users may want to upload a different CV for this application
    });
  }

  /// Check if CV field is valid based on dynamic configuration
  bool _isCVValid() {
    final isRequired = _formConfig?.isFieldRequired('cv') ?? true;
    return !isRequired || _selectedCV != null;
  }

  /// Check if CV error state should be displayed
  bool _shouldShowCVError() {
    return _cvFieldTouched && !_isCVValid();
  }

  bool _validateDynamicFields() {
    if (_formConfig == null) return false;

    // Collect field values for validation including CV
    final fieldValues = <String, dynamic>{
      'programme': _selectedProgramme,
      'studyYear': _studyYear,
      'masterTitle': _masterTitleController.text.trim(),
      'linkedin': _linkedinController.text.trim(),
      'motivationText': _motivationController.text.trim(),
      'cv': _selectedCV, // Include CV in validation
    };

    // Check if all required fields have values
    if (!_formConfig!.validateRequiredFields(fieldValues)) {
      final missingFields = _formConfig!.getMissingRequiredFields(fieldValues);
      final message = missingFields.length == 1
          ? '${missingFields.first} is required'
          : 'Please complete all required fields: ${missingFields.join(', ')}';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: ArkadColors.lightRed),
      );
      return false;
    }

    return true;
  }

  Future<void> _submitApplication() async {
    // Mark CV field as touched to show validation errors
    setState(() => _cvFieldTouched = true);

    if (!_formKey.currentState!.validate()) return;

    // Validate dynamic fields based on configuration
    if (!_validateDynamicFields()) return;

    // Session availability controlled by server data (available field, userStatus)

    final viewModel = Provider.of<StudentSessionViewModel>(
      context,
      listen: false,
    );

    // CV upload is now integrated with application submission
    await viewModel.applyForSession(
      companyId: int.parse(widget.companyId),
      motivationText: _motivationController.text.trim(),
      programme: ProgrammeUtils.programmeToLabel(_selectedProgramme),
      linkedin: _linkedinController.text.trim().isEmpty
          ? null
          : ValidationService.buildLinkedInUrl(_linkedinController.text.trim()),
      masterTitle: _masterTitleController.text.trim(),
      studyYear: _studyYear,
      cvFile: _selectedCV,
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

    // Success and error messages are handled by the Consumer logic above
    await viewModel.retryCVUpload(
      companyId: int.parse(widget.companyId),
      file: _selectedCV!,
    );
  }

  /// Smart message handling with guards to prevent setState during build
  void _handleCommandMessages(StudentSessionViewModel viewModel) {
    final command = viewModel.applyForSessionCommand;

    // Handle application success messages
    if (command.showSuccessMessage && !_hasHandledApplicationSuccess) {
      _hasHandledApplicationSuccess = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                command.successMessage ?? 'Application submitted successfully!',
              ),
              backgroundColor: ArkadColors.arkadGreen,
            ),
          );

          command.clearSuccessMessage();

          // Navigate back after a short delay to ensure data refresh completes
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted && context.mounted && context.canPop()) {
              context.pop();
            }
            // Reset command state after navigation
            viewModel.applyForSessionCommand.reset();
          });
        }
      });
    } else if (!command.showSuccessMessage) {
      _hasHandledApplicationSuccess = false; // Reset when message is cleared
    }

    // Handle application error messages
    if (command.showErrorMessage && !_hasHandledApplicationError) {
      _hasHandledApplicationError = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final errorMessage =
              command.errorMessage ?? 'An error occurred. Please try again.';
          final showRetryOption =
              errorMessage.contains('CV') && _selectedCV != null;

          // Handle specific 401 authentication errors
          if (errorMessage.contains('session has expired') ||
              errorMessage.contains('Unauthorized')) {
            final authViewModel = Provider.of<AuthViewModel>(
              context,
              listen: false,
            );
            authViewModel.signOut();

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && context.mounted) {
                context.go('/auth/login');
              }
            });
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: ArkadColors.lightRed,
              action: showRetryOption
                  ? SnackBarAction(
                      label: 'Retry CV Upload',
                      textColor: ArkadColors.white,
                      onPressed: () => _retryCVUpload(viewModel),
                    )
                  : null,
            ),
          );

          command.clearErrorMessage();
        }
      });
    } else if (!command.showErrorMessage) {
      _hasHandledApplicationError = false; // Reset when message is cleared
    }
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
          // Handle command messages using the proper notification pipeline
          _handleCommandMessages(viewModel);

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
            // Header Section with session info and timeline warning
            _buildHeaderSection(),

            // Application Form Sections
            ..._buildApplicationSections(),

            // Footer Section with disclaimer and submit button
            _buildFooterSection(isSubmitting),
          ],
        ),
      ),
    );
  }

  /// Build header section with session info
  Widget _buildHeaderSection() {
    return Column(children: [_buildSessionInfo(), const SizedBox(height: 16)]);
  }

  /// Build application form sections dynamically based on field configuration
  List<Widget> _buildApplicationSections() {
    final sections = <Widget>[];

    // Motivation Section - prioritized at top if visible
    if (_formConfig?.shouldShowField('motivationText') ?? true) {
      sections.addAll([
        _buildFormSection(
          title: 'Your Motivation',
          icon: Icons.edit_outlined,
          child: _buildMotivationField(),
        ),
        const SizedBox(height: 20),
      ]);
    }

    // Required Fields Section - always shown to include CV upload
    final hasOtherRequiredFields =
        _formConfig?.getRequiredVisibleFields().isNotEmpty ?? false;
    sections.addAll([
      _buildFormSection(
        title: hasOtherRequiredFields
            ? 'Required Information'
            : 'Document Upload',
        icon: Icons.assignment_outlined,
        child: _buildRequiredFields(),
      ),
      const SizedBox(height: 20),
    ]);

    // Optional Fields Section
    if (_formConfig?.hasOptionalFields ?? false) {
      sections.addAll([
        _buildFormSection(
          title: 'Additional Information',
          subtitle:
              'These fields are optional and can help strengthen your application',
          icon: Icons.info_outlined,
          child: _buildOptionalFields(),
        ),
        const SizedBox(height: 20),
      ]);
    }

    return sections;
  }

  /// Build footer section with disclaimer and submit button
  Widget _buildFooterSection(bool isSubmitting) {
    return Column(
      children: [
        // Disclaimer Section (if provided)
        if (_session!.disclaimer != null &&
            _session!.disclaimer!.isNotEmpty) ...[
          _buildDisclaimerSection(),
          const SizedBox(height: 24),
        ],

        const SizedBox(height: 16),
        _buildSubmitButton(isSubmitting),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Build a standardized form section with consistent styling
  Widget _buildFormSection({
    required String title,
    String? subtitle,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ArkadColors.arkadNavy.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArkadColors.arkadTurkos.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: ArkadColors.arkadTurkos, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: ArkadColors.white,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: ArkadColors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  /// Build disclaimer section with distinct styling
  Widget _buildDisclaimerSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: ArkadColors.arkadNavy.withValues(alpha: 0.3),
        border: Border.all(
          color: ArkadColors.arkadTurkos.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: ArkadColors.arkadTurkos,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Important Information',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ArkadColors.arkadTurkos,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _session!.disclaimer!,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
              color: ArkadColors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo() {
    final hasDescription = _session!.description != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ArkadColors.arkadLightNavy, ArkadColors.arkadNavy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ArkadColors.arkadLightNavy.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, hasDescription ? 24 : 20),
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
                    color: ArkadColors.white.withValues(alpha: 0.1),
                  ),
                  child: CompanyLogoImage(
                    logoUrl: _session!.logoUrl,
                    size: 56,
                    borderRadius: BorderRadius.circular(16),
                    fallbackWidget: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: ArkadColors.white.withValues(alpha: 0.2),
                      ),
                      child: const Icon(
                        Icons.business_rounded,
                        color: ArkadColors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _session!.companyName,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ArkadColors.white,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: ArkadColors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Student Session Application',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ArkadColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Always show additional content section to balance the layout
            const SizedBox(height: 16),
            _session!.description != null
                ? Text(
                    _session!.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: ArkadColors.white,
                      height: 1.5,
                    ),
                  )
                : _buildDefaultSessionInfo(),
          ],
        ),
      ),
    );
  }

  /// Build default session info when no description is provided
  Widget _buildDefaultSessionInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: ArkadColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.groups_outlined,
                color: ArkadColors.white.withValues(alpha: 0.9),
                size: 16,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Exclusive Student Session',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArkadColors.white.withValues(alpha: 0.95),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Connect with industry professionals, gain insights into company culture, and explore potential career opportunities.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: ArkadColors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip('Career Insights', Icons.lightbulb_outline),
            const SizedBox(width: 8),
            _buildInfoChip('Networking', Icons.connect_without_contact),
          ],
        ),
      ],
    );
  }

  /// Build small info chips for the default session info
  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ArkadColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ArkadColors.white.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ArkadColors.white.withValues(alpha: 0.8), size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ArkadColors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationField() {
    if (_formConfig == null ||
        !_formConfig!.shouldShowField('motivationText')) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Explain why you want to participate in this Student Session (max 300 words)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: ArkadColors.white.withValues(alpha: 0.8),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _motivationController,
          decoration: InputDecoration(
            labelText: _formConfig!.getFieldLabel(
              'Your motivation',
              'motivationText',
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            alignLabelWithHint: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            helperText: 'Share your interests and goals for this session',
          ),
          maxLines: 8,
          validator: (value) {
            // Use dynamic validator first
            final dynamicValidator = _formConfig?.getTextFieldValidator(
              'motivationText',
            );
            if (dynamicValidator != null) {
              final result = dynamicValidator(value);
              if (result != null) return result;
            }

            // Add specific motivation validation (word count)
            if (value != null &&
                value.trim().isNotEmpty &&
                _motivationWordCount > 300) {
              return 'Motivation must be 300 words or less';
            }

            return null;
          },
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (_motivationWordCount > 280)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color:
                      (_motivationWordCount > 300
                              ? ArkadColors.lightRed
                              : ArkadColors.arkadOrange)
                          .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        (_motivationWordCount > 300
                                ? ArkadColors.lightRed
                                : ArkadColors.arkadOrange)
                            .withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _motivationWordCount > 300
                      ? 'Too many words'
                      : 'Approaching limit',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _motivationWordCount > 300
                        ? ArkadColors.lightRed
                        : ArkadColors.arkadOrange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
            else
              const SizedBox.shrink(),
            Text(
              '$_motivationWordCount / 300 words',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: _motivationWordCount > 300
                    ? ArkadColors.lightRed
                    : ArkadColors.white.withValues(alpha: 0.7),
                fontWeight: _motivationWordCount > 300 ? FontWeight.w600 : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionalFields() {
    if (_formConfig == null) return const SizedBox.shrink();

    final optionalFields = <Widget>[];

    // Programme Dropdown (if optional)
    if (_formConfig!.shouldShowInOptionalSection('programme')) {
      optionalFields.add(_buildProgrammeField(isOptional: true));
      optionalFields.add(const SizedBox(height: 16));
    }

    // Study Year Dropdown (if optional)
    if (_formConfig!.shouldShowInOptionalSection('studyYear')) {
      optionalFields.add(_buildStudyYearField(isOptional: true));
      optionalFields.add(const SizedBox(height: 16));
    }

    // Master Title Field (if optional)
    if (_formConfig!.shouldShowInOptionalSection('masterTitle')) {
      optionalFields.add(_buildMasterTitleField(isOptional: true));
      optionalFields.add(const SizedBox(height: 16));
    }

    // LinkedIn field (if optional)
    if (_formConfig!.shouldShowInOptionalSection('linkedin')) {
      optionalFields.add(_buildLinkedInField(isOptional: true));
      optionalFields.add(const SizedBox(height: 16));
    }

    // CV Upload Section (if optional)
    if (_formConfig!.shouldShowInOptionalSection('cv')) {
      optionalFields.add(_buildCVUploadSection(isOptional: true));
    }

    if (optionalFields.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: optionalFields,
    );
  }

  // Unified field builders that work in both required and optional sections

  Widget _buildProgrammeField({bool isOptional = false}) {
    return DropdownButtonFormField<Programme>(
      decoration: InputDecoration(
        labelText: _formConfig!.getFieldLabel('Programme', 'programme'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      initialValue:
          _selectedProgramme != null &&
              availableProgrammes.any((p) => p.value == _selectedProgramme)
          ? _selectedProgramme
          : null, // Reset to null if selected programme is not in list
      hint: const Text('Select your programme'),
      validator: isOptional
          ? null
          : _formConfig!.getDropdownValidator('programme'),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down),
      menuMaxHeight: 350,
      items: availableProgrammes.map((program) {
        return DropdownMenuItem<Programme>(
          value: program.value,
          child: Text(program.label, overflow: TextOverflow.ellipsis),
        );
      }).toList(),
      onChanged: (Programme? newValue) {
        setState(() {
          _selectedProgramme = newValue;
        });
      },
    );
  }

  Widget _buildStudyYearField({bool isOptional = false}) {
    return DropdownButtonFormField<int>(
      decoration: InputDecoration(
        labelText: _formConfig!.getFieldLabel('Study Year', 'studyYear'),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
      ),
      initialValue: _studyYear != null && _studyYear! >= 1 && _studyYear! <= 5
          ? _studyYear
          : null,
      hint: const Text('Select your study year'),
      validator: isOptional
          ? null
          : _formConfig!.getDropdownValidator('studyYear'),
      items: [1, 2, 3, 4, 5].map((year) {
        return DropdownMenuItem<int>(value: year, child: Text('Year $year'));
      }).toList(),
      onChanged: (int? newValue) {
        setState(() {
          _studyYear = newValue;
        });
      },
    );
  }

  Widget _buildMasterTitleField({bool isOptional = false}) {
    return ArkadFormField(
      controller: _masterTitleController,
      labelText: _formConfig!.getFieldLabel('Master\'s Title', 'masterTitle'),
      hintText: 'Your master\'s programme title',
      validator: _formConfig!.getTextFieldValidator('masterTitle'),
    );
  }

  Widget _buildLinkedInField({bool isOptional = false}) {
    return ArkadFormField(
      controller: _linkedinController,
      labelText: _formConfig!.getFieldLabel('LinkedIn Profile', 'linkedin'),
      hintText: 'e.g., https://www.linkedin.com/in/yourprofile',
      validator: _formConfig!.getTextFieldValidator('linkedin'),
    );
  }

  Widget _buildRequiredFields() {
    if (_formConfig == null) return const SizedBox.shrink();

    final requiredFields = <Widget>[];

    // Programme Dropdown (if required and visible)
    if (_formConfig!.shouldShowInRequiredSection('programme')) {
      requiredFields.add(_buildProgrammeField());
      requiredFields.add(const SizedBox(height: 16));
    }

    // Study Year Dropdown (if required and visible)
    if (_formConfig!.shouldShowInRequiredSection('studyYear')) {
      requiredFields.add(_buildStudyYearField());
      requiredFields.add(const SizedBox(height: 16));
    }

    // Master Title Field (if required and visible)
    if (_formConfig!.shouldShowInRequiredSection('masterTitle')) {
      requiredFields.add(_buildMasterTitleField());
      requiredFields.add(const SizedBox(height: 16));
    }

    // LinkedIn field (if required and visible)
    if (_formConfig!.shouldShowInRequiredSection('linkedin')) {
      requiredFields.add(_buildLinkedInField());
      requiredFields.add(const SizedBox(height: 16));
    }

    // CV Upload Section (if required and visible)
    if (_formConfig!.shouldShowInRequiredSection('cv')) {
      requiredFields.addAll([
        if (requiredFields.isNotEmpty) const SizedBox(height: 8),
        _buildCVUploadSection(),
      ]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requiredFields,
    );
  }

  Widget _buildCVUploadSection({bool isOptional = false}) {
    final cvLabel =
        _formConfig?.getFieldLabel('CV / Resume', 'cv') ?? 'CV / Resume';
    final isRequired =
        !isOptional && (_formConfig?.isFieldRequired('cv') ?? true);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          cvLabel,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: _shouldShowCVError()
                  ? ArkadColors.lightRed.withValues(alpha: 0.6)
                  : _selectedCV != null
                  ? ArkadColors.arkadGreen.withValues(alpha: 0.5)
                  : ArkadColors.white.withValues(alpha: 0.2),
              width: _shouldShowCVError() ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: _shouldShowCVError()
                ? ArkadColors.lightRed.withValues(alpha: 0.15)
                : _selectedCV != null
                ? ArkadColors.arkadGreen.withValues(alpha: 0.1)
                : ArkadColors.arkadNavy.withValues(alpha: 0.2),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _shouldShowCVError()
                        ? Icons.error_outline
                        : _selectedCV != null
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _shouldShowCVError()
                        ? ArkadColors.lightRed
                        : _selectedCV != null
                        ? ArkadColors.arkadGreen
                        : ArkadColors.white.withValues(alpha: 0.7),
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shouldShowCVError()
                              ? 'CV Required - Please select a file'
                              : _selectedCV != null
                              ? 'CV Selected: ${_selectedCV!.name}'
                              : isRequired
                              ? 'CV Required - No file selected'
                              : 'CV - No file selected (Optional)',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: _shouldShowCVError()
                                    ? ArkadColors.lightRed
                                    : _selectedCV != null
                                    ? ArkadColors.arkadGreen
                                    : ArkadColors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PDF format only, max 10MB',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: ArkadColors.white.withValues(alpha: 0.6),
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
                      icon: const Icon(
                        Icons.attach_file,
                        color: ArkadColors.white,
                      ),
                      label: Text(
                        _selectedCV != null ? 'Change CV' : 'Select CV File',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArkadColors.arkadTurkos,
                        foregroundColor: ArkadColors.white,
                      ),
                    ),
                  ),
                  if (_selectedCV != null) ...[
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _selectedCV = null),
                      icon: const Icon(
                        Icons.delete,
                        color: ArkadColors.lightRed,
                      ),
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
        if (_shouldShowCVError()) ...[
          const SizedBox(height: 8),
          Text(
            'CV is required for this application',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: ArkadColors.lightRed,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickCV() async {
    final fileService = serviceLocator<FileService>();
    final platformFile = await fileService.pickCVFile(context: context);

    if (platformFile != null) {
      setState(() {
        _selectedCV = platformFile;
        _cvFieldTouched = false; // Reset error state when valid file selected
      });
    }
  }

  Widget _buildSubmitButton(bool isSubmitting) {
    // Use dynamic field validation
    bool hasAllRequiredFields = true;
    List<String> missingFields = [];

    // Form config should always be available when form is displayed
    if (_formConfig == null) {
      // This should not happen - form is only shown with valid session data
      hasAllRequiredFields = false;
    } else {
      final fieldValues = <String, dynamic>{
        'programme': _selectedProgramme,
        'studyYear': _studyYear,
        'masterTitle': _masterTitleController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'motivationText': _motivationController.text.trim(),
        'cv': _selectedCV, // Include CV in validation
      };

      hasAllRequiredFields =
          _formConfig!.validateRequiredFields(fieldValues) &&
          _motivationWordCount <= 300;

      if (!hasAllRequiredFields) {
        missingFields = _formConfig!.getMissingRequiredFields(fieldValues);
        if (_motivationWordCount > 300) {
          missingFields.add('valid motivation (≤300 words)');
        }
      }
    }

    // Data availability controls user flow - only check form validity
    final canSubmit = !isSubmitting && hasAllRequiredFields;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!hasAllRequiredFields) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: ArkadColors.lightRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: ArkadColors.lightRed.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_rounded,
                  color: ArkadColors.lightRed,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    missingFields.isNotEmpty
                        ? 'Please complete all required fields: ${missingFields.join(', ')}.'
                        : 'Please complete all required fields.',
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
              backgroundColor: canSubmit
                  ? ArkadColors.arkadTurkos
                  : ArkadColors.gray,
              foregroundColor: ArkadColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: ArkadColors.white,
                    ),
                  )
                : Text(
                    _selectedCV != null
                        ? 'Submit Application with CV'
                        : 'Submit Application',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
