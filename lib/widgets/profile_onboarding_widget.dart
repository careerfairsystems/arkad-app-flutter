import 'dart:io';

import 'package:arkad/models/programme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../config/theme_config.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../utils/profile_utils.dart';
// For the Programme enum and PROGRAMS

class ProfileOnboardingWidget extends StatefulWidget {
  final User user;
  final Function onProfileUpdated;

  const ProfileOnboardingWidget({
    super.key,
    required this.user,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileOnboardingWidget> createState() =>
      _ProfileOnboardingWidgetState();
}

class _ProfileOnboardingWidgetState extends State<ProfileOnboardingWidget>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final AnimationController _animationController;
  final ImagePicker _imagePicker = ImagePicker();

  // Form field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _programmeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _masterTitleController = TextEditingController();
  final _foodPreferencesController = TextEditingController();
  int? _studyYear;
  Programme? _selectedProgramme;

  // File selection
  File? _selectedProfileImage;
  File? _selectedCV;
  bool _profilePictureDeleted = false;
  bool _cvDeleted = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateFields(widget.user);

      // Initialize the profile provider
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      profileProvider.initialize(widget.user);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _programmeController.dispose();
    _linkedinController.dispose();
    _masterTitleController.dispose();
    _foodPreferencesController.dispose();

    // Bug fix: Properly handle file resources to prevent memory leaks
    _selectedProfileImage = null;
    _selectedCV = null;

    super.dispose();
  }

  void _populateFields(User user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _programmeController.text = user.programme ?? '';
    _linkedinController.text = user.linkedin ?? '';
    _masterTitleController.text = user.masterTitle ?? '';
    _foodPreferencesController.text = user.foodPreferences ?? '';
    _studyYear = user.studyYear;

    // Convert string programme to enum if it exists
    _selectedProgramme = ProfileUtils.programmeStringToEnum(user.programme);
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ProfileUtils.pickProfileImage(
        context: context,
        imagePicker: _imagePicker,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedProfileImage = pickedFile;
          _profilePictureDeleted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
      }
    }
  }

  Future<void> _pickCV() async {
    try {
      final pickedFile = await ProfileUtils.pickCVFile(context: context);

      if (pickedFile != null) {
        setState(() {
          _selectedCV = pickedFile;
          _cvDeleted = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking CV: $e')));
      }
    }
  }

  Widget _buildCustomStepIndicator(int currentStep, int totalSteps) {
    return Column(
      children: [
        // Animated step progress indicator
        Padding(
          padding: const EdgeInsets.only(top: 8.0, bottom: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              bool isActive = index <= currentStep;
              bool isCurrent = index == currentStep;

              return Row(
                children: [
                  // Step circle
                  Container(
                    width: isCurrent ? 36.0 : 30.0,
                    height: isCurrent ? 36.0 : 30.0,
                    decoration: BoxDecoration(
                      color:
                          isActive
                              ? ArkadColors.arkadTurkos
                              : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(18),
                      border:
                          isCurrent
                              ? Border.all(
                                color: ArkadColors.arkadTurkos.withValues(
                                  alpha: 0.3,
                                ),
                                width: 4,
                              )
                              : null,
                      boxShadow:
                          isCurrent
                              ? [
                                BoxShadow(
                                  color: ArkadColors.arkadTurkos.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: isCurrent ? 16 : 14,
                        ),
                      ),
                    ),
                  ),
                  // Connector line
                  if (index < totalSteps - 1)
                    Container(
                      width: 50,
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color:
                            isActive
                                ? ArkadColors.arkadTurkos
                                : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCenteredProfilePicture() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Profile picture
          CircleAvatar(
            radius: 60,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                _selectedProfileImage != null
                    ? FileImage(_selectedProfileImage!)
                    : (!_profilePictureDeleted &&
                            widget.user.profilePicture != null
                        ? NetworkImage(widget.user.profilePicture!)
                            as ImageProvider
                        : null),
            child:
                (_selectedProfileImage == null &&
                        (_profilePictureDeleted ||
                            widget.user.profilePicture == null ||
                            widget.user.profilePicture!.isEmpty))
                    ? const Icon(Icons.person, size: 60, color: Colors.grey)
                    : null,
          ),

          // Edit button
          Positioned(
            bottom: 0,
            right: 0,
            child: Material(
              color: ArkadColors.arkadTurkos,
              shape: const CircleBorder(),
              elevation: 4,
              child: InkWell(
                onTap: _pickImage,
                customBorder: const CircleBorder(),
                splashColor: Colors.white24,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Icon(Icons.camera_alt, size: 22, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoStep(ProfileProvider provider) {
    final bool needsFirstName = provider.missingRequiredFields.contains(
      'First Name',
    );
    final bool needsLastName = provider.missingRequiredFields.contains(
      'Last Name',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(
            'Personal Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ArkadColors.arkadNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Let\'s get to know you better',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Centered profile picture with modern styling
          _buildCenteredProfilePicture(),

          // Profile picture removal
          if (widget.user.profilePicture != null && !_profilePictureDeleted)
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedProfileImage = null;
                  _profilePictureDeleted = true;
                });
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text(
                'Remove Picture',
                style: TextStyle(color: Colors.red),
              ),
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),

          // Name fields with improved styling
          if (needsFirstName)
            TextFormField(
              controller: _firstNameController,
              decoration: InputDecoration(
                labelText: 'First Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.person_outline),
                helperText: 'Required',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'First name is required';
                }
                return null;
              },
            ),

          if (needsFirstName) const SizedBox(height: 16),

          if (needsLastName)
            TextFormField(
              controller: _lastNameController,
              decoration: InputDecoration(
                labelText: 'Last Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.person_outline),
                helperText: 'Required',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Last name is required';
                }
                return null;
              },
            ),

          // Show message if all fields in this section are complete
          if (!needsFirstName && !needsLastName)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your basic information is complete. You can update it if needed.',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEducationStep(ProfileProvider provider) {
    final bool needsProgramme = provider.missingRequiredFields.contains(
      'Programme',
    );
    final bool needsStudyYear = provider.missingRequiredFields.contains(
      'Study Year',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(
            'Education Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ArkadColors.arkadNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tell us about your academic background',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Programme field with improved styling
          if (needsProgramme) ...[
            DropdownButtonFormField<Programme>(
              decoration: InputDecoration(
                labelText: 'Programme *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.school_outlined),
                helperText: 'Required',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
              value: _selectedProgramme,
              hint: const Text('Select your programme'),
              validator: (value) {
                if (value == null) {
                  return 'Programme is required';
                }
                return null;
              },
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              menuMaxHeight: 350,
              items:
                  programs.map((program) {
                    return DropdownMenuItem<Programme>(
                      value: program['value'] as Programme,
                      child: Text(
                        program['label'] as String,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }).toList(),
              onChanged: (Programme? newValue) {
                setState(() {
                  _selectedProgramme = newValue;
                  if (newValue != null) {
                    _programmeController.text =
                        programs
                            .firstWhere(
                              (program) => program['value'] == newValue,
                            )['label']
                            .toString();
                  }
                });
              },
            ),
            const SizedBox(height: 24),
          ],

          // Study year field with improved styling
          if (needsStudyYear) ...[
            DropdownButtonFormField<int>(
              decoration: InputDecoration(
                labelText: 'Study Year *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.calendar_today_outlined),
                helperText: 'Required',
              ),
              value: _studyYear,
              hint: const Text('Select your study year'),
              validator: (value) {
                if (value == null) {
                  return 'Study year is required';
                }
                return null;
              },
              items:
                  [1, 2, 3, 4, 5].map((year) {
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
            const SizedBox(height: 24),
          ],

          // Master title field (always shown as optional)
          TextFormField(
            controller: _masterTitleController,
            decoration: InputDecoration(
              labelText: 'Master Title',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.school),
              helperText: 'Optional',
            ),
            textCapitalization: TextCapitalization.words,
          ),

          // Show message if all required fields in this section are complete
          if (!needsProgramme && !needsStudyYear)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your education information is complete. You can update it if needed.',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfoStep(ProfileProvider provider) {
    final bool needsFoodPreferences = provider.missingRequiredFields.contains(
      'Food Preferences',
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          Text(
            'Additional Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: ArkadColors.arkadNavy,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Help us accommodate your needs and connect with you',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 15),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Food preferences field with improved styling
          if (needsFoodPreferences) ...[
            TextFormField(
              controller: _foodPreferencesController,
              decoration: InputDecoration(
                labelText: 'Food Preferences *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                prefixIcon: const Icon(Icons.restaurant_menu),
                helperText: 'Required (allergies, vegetarian, etc. or "None")',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Food preferences are required (put "None" if not applicable)';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],

          // LinkedIn field with improved styling
          TextFormField(
            controller: _linkedinController,
            decoration: InputDecoration(
              labelText: 'LinkedIn URL',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              prefixIcon: const Icon(Icons.link),
              helperText: 'Optional - Connect with recruiters and peers',
            ),
          ),
          const SizedBox(height: 24),

          // CV upload with improved styling
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resume / CV',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Current CV status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedCV != null ||
                                (!_cvDeleted &&
                                    widget.user.cv != null &&
                                    widget.user.cv!.isNotEmpty)
                            ? Icons.check_circle
                            : Icons.upload_file,
                        color:
                            _selectedCV != null ||
                                    (!_cvDeleted &&
                                        widget.user.cv != null &&
                                        widget.user.cv!.isNotEmpty)
                                ? Colors.green
                                : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _selectedCV != null
                              ? 'Selected: ${_selectedCV!.path.split('/').last}'
                              : (_cvDeleted
                                  ? 'No CV selected yet (PDF format)'
                                  : (widget.user.cv != null &&
                                          widget.user.cv!.isNotEmpty
                                      ? 'Current: ${widget.user.cv!.split('/').last}'
                                      : 'No CV selected yet (PDF format)')),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // CV actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArkadColors.arkadTurkos,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _pickCV,
                        icon: const Icon(Icons.file_upload),
                        label: Text(
                          widget.user.cv != null && widget.user.cv!.isNotEmpty
                              ? 'Change CV'
                              : 'Upload CV',
                        ),
                      ),
                    ),
                    if (!_cvDeleted &&
                        widget.user.cv != null &&
                        widget.user.cv!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _selectedCV = null;
                            _cvDeleted = true;
                          });
                        },
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        tooltip: 'Remove CV',
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Show message if all required fields in this section are complete
          if (!needsFoodPreferences)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your required information is complete. Optional fields can still be updated.',
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(ProfileProvider provider) {
    final List<Widget> stepWidgets = [];

    for (int i = 0; i < provider.steps.length; i++) {
      Map<String, dynamic> step = provider.steps[i];
      String stepId = step['id'] as String;

      // Check if this step has any required fields that are missing
      bool hasRequiredFieldsMissing = (step['requiredFields'] as List).any(
        (field) => provider.missingRequiredFields.contains(field),
      );

      // Check if this step has any optional fields
      bool hasOptionalFields = (step['optionalFields'] as List).isNotEmpty;

      // Only include this step if it has required fields missing or optional fields
      if (hasRequiredFieldsMissing || hasOptionalFields) {
        switch (stepId) {
          case 'basic':
            stepWidgets.add(_buildBasicInfoStep(provider));
          case 'education':
            stepWidgets.add(_buildEducationStep(provider));
          case 'preferences':
            stepWidgets.add(_buildAdditionalInfoStep(provider));
        }
      }
    }

    return stepWidgets;
  }

  Future<void> _nextStep(ProfileProvider provider) async {
    if (_formKey.currentState!.validate()) {
      if (provider.currentStep < provider.totalSteps - 1) {
        await provider.nextStep();
        await _animationController.forward(from: 0.0);
      } else {
        await _submitForm();
      }
    }
  }

  Future<void> _previousStep(ProfileProvider provider) async {
    if (provider.currentStep > 0) {
      await provider.previousStep();
      await _animationController.forward(from: 0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileProvider>(
      builder: (context, profileProvider, _) {
        if (profileProvider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: ArkadColors.arkadTurkos),
          );
        }

        // If all required fields are completed, don't show the widget
        if (!profileProvider.hasIncompleteRequiredFields) {
          return const SizedBox.shrink();
        }

        final steps = _buildSteps(profileProvider);

        if (steps.isEmpty) {
          return const SizedBox.shrink(); // No steps needed
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: Card(
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(
                  color: ArkadColors.arkadTurkos.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
              elevation: 8,
              shadowColor: ArkadColors.arkadTurkos.withValues(alpha: 0.2),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            ArkadColors.arkadNavy,
                            ArkadColors.arkadTurkos,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Complete Your Profile',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Unlock all features by completing your profile',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodyMedium?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.85),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(profileProvider.currentStep + 1)}/${profileProvider.totalSteps}',
                              style: TextStyle(
                                color: ArkadColors.arkadNavy,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Step indicator
                    _buildCustomStepIndicator(
                      profileProvider.currentStep,
                      profileProvider.totalSteps,
                    ),

                    // Content area with scrolling
                    Flexible(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (
                                Widget child,
                                Animation<double> animation,
                              ) {
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: Container(
                                key: ValueKey<int>(profileProvider.currentStep),
                                constraints: const BoxConstraints(
                                  minHeight: 400,
                                ),
                                child: steps[profileProvider.currentStep],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Navigation buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade300,
                            blurRadius: 4,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Back button
                          if (profileProvider.currentStep > 0)
                            TextButton.icon(
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back'),
                              style: TextButton.styleFrom(
                                foregroundColor: ArkadColors.arkadNavy,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onPressed:
                                  _isSubmitting
                                      ? null
                                      : () => _previousStep(profileProvider),
                            )
                          else
                            const SizedBox.shrink(),

                          // Next/Submit button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ArkadColors.arkadTurkos,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () => _nextStep(profileProvider),
                            child:
                                _isSubmitting
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    )
                                    : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          profileProvider.currentStep <
                                                  profileProvider.totalSteps - 1
                                              ? 'Continue'
                                              : 'Complete',
                                        ),
                                        if (profileProvider.currentStep <
                                            profileProvider.totalSteps - 1) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward,
                                            size: 18,
                                          ),
                                        ],
                                      ],
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      // Store all context-dependent objects before async operations
      final context = this.context;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final profileProvider = Provider.of<ProfileProvider>(
        context,
        listen: false,
      );
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        // Prepare profile data
        final profileData = profileProvider.prepareProfileData(
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          selectedProgramme: _selectedProgramme,
          programmeText: _programmeController.text,
          linkedin: _linkedinController.text,
          masterTitle: _masterTitleController.text,
          studyYear: _studyYear,
          foodPreferences: _foodPreferencesController.text,
        );

        // Update the user profile using the centralized provider
        final success = await profileProvider.updateProfile(
          profileData: profileData,
          profilePicture: _selectedProfileImage,
          deleteProfilePicture: _profilePictureDeleted,
          cv: _selectedCV,
          deleteCV: _cvDeleted,
        );

        if (success && mounted) {
          // Refresh the user profile in the auth provider
          await authProvider.refreshUserProfile();

          // Notify parent that profile was updated
          widget.onProfileUpdated();

          // Show success message
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: ${e.toString()}'),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }
}
