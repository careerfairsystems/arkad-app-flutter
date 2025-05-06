import 'dart:io';

import 'package:arkad/models/user.dart';
import 'package:arkad/services/user_service.dart';
import 'package:arkad/utils/profile_utils.dart';
import 'package:arkad/utils/service_helper.dart';
import 'package:arkad/widgets/profile_form_components.dart';
// We'll still use file_picker but with a fallback approach
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Import updated packages
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

// Define the Programme enum
enum Programme {
  architecture,
  automotive,
  automation,
  biomedicalEngineering,
  chemicalEngineering,
  civilEngineering,
  computerScienceEngineering,
  constructionAndArchitecture,
  constructionAndRailwayConstruction,
  roadAndTrafficTechnology,
  electricalEngineering,
  engineeringBiotechnology,
  informationAndCommunicationEngineering,
  engineeringMathematics,
  engineeringNanoscience,
  engineeringPhysics,
  environmentalEngineering,
  fireProtectionEngineering,
  industrialDesign,
  industrialEconomicsAndManagement,
  surveying,
  mechanicalEngineering,
  mechanicalEngineeringWithIndustrialDesign,
  riskSafetyAndCrisisManagement,
}

// Program options
const programs = [
  {'label': "Architecture", 'value': Programme.architecture},
  {'label': "Automotive", 'value': Programme.automotive},
  {'label': "Automation", 'value': Programme.automation},
  {'label': "Biomedical Engineering", 'value': Programme.biomedicalEngineering},
  {'label': "Chemical Engineering", 'value': Programme.chemicalEngineering},
  {'label': "Civil Engineering", 'value': Programme.civilEngineering},
  {
    'label': "Computer Science and Engineering",
    'value': Programme.computerScienceEngineering
  },
  {
    'label': "Construction and Architecture",
    'value': Programme.constructionAndArchitecture
  },
  {
    'label': "Construction and Railway Construction",
    'value': Programme.constructionAndRailwayConstruction
  },
  {'label': "Traffic and Road", 'value': Programme.roadAndTrafficTechnology},
  {'label': "Electrical Engineering", 'value': Programme.electricalEngineering},
  {
    'label': "Engineering Biotechnology",
    'value': Programme.engineeringBiotechnology
  },
  {
    'label': "Information and Communication Engineering",
    'value': Programme.informationAndCommunicationEngineering
  },
  {
    'label': "Engineering Mathematics",
    'value': Programme.engineeringMathematics
  },
  {
    'label': "Engineering Nanoscience",
    'value': Programme.engineeringNanoscience
  },
  {'label': "Engineering Physics", 'value': Programme.engineeringPhysics},
  {
    'label': "Environmental Engineering",
    'value': Programme.environmentalEngineering
  },
  {
    'label': "Fire Protection Engineering",
    'value': Programme.fireProtectionEngineering
  },
  {'label': "Industrial Design", 'value': Programme.industrialDesign},
  {
    'label': "Industrial Engineering and Management",
    'value': Programme.industrialEconomicsAndManagement
  },
  {'label': "Surveying", 'value': Programme.surveying},
  {'label': "Mechanical Engineering", 'value': Programme.mechanicalEngineering},
  {
    'label': "Mechanical Engineering with Technical Design",
    'value': Programme.mechanicalEngineeringWithIndustrialDesign
  },
  {
    'label': "Risk, Safety and Crisis Management",
    'value': Programme.riskSafetyAndCrisisManagement
  },
];

class ProfileCompletionDialog extends StatefulWidget {
  const ProfileCompletionDialog({super.key});

  @override
  State<ProfileCompletionDialog> createState() =>
      _ProfileCompletionDialogState();
}

class _ProfileCompletionDialogState extends State<ProfileCompletionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Page controller for multi-step form
  final PageController _pageController = PageController();

  // Form field controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _programmeController = TextEditingController();
  final _linkedinController = TextEditingController();
  final _masterTitleController = TextEditingController();
  final _foodPreferencesController = TextEditingController();
  int? _studyYear;

  File? _selectedProfileImage;
  File? _selectedCV;
  bool _isUploading = false;

  bool _isLoading = false;
  User? _initialUserData;

  final ImagePicker _imagePicker = ImagePicker();

  Programme? _selectedProgramme;
  bool _profilePictureDeleted = false;
  bool _cvDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoading = true;
    });

    try {
      if (authProvider.user != null) {
        _initialUserData = authProvider.user;
        _populateFields(_initialUserData!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to load profile data: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _populateFields(User user) {
    _firstNameController.text = user.firstName ?? '';
    _lastNameController.text = user.lastName ?? '';
    // Use programmeController for storage of the string value, but convert to enum for UI
    _programmeController.text = user.programme ?? '';

    // Convert string programme to enum if it exists
    _selectedProgramme = ProfileUtils.programmeStringToEnum(user.programme);

    _linkedinController.text = user.linkedin ?? '';
    _masterTitleController.text = user.masterTitle ?? '';
    _foodPreferencesController.text = user.foodPreferences ?? '';
    _studyYear = user.studyYear;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _programmeController.dispose();
    _linkedinController.dispose();
    _masterTitleController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }

  // Pick profile image
  Future<void> _pickProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedProfileImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  // Modified CV picker with fallback approach
  Future<void> _pickCVFile() async {
    try {
      // First attempt with file_picker
      try {
        fp.FilePickerResult? result = await fp.FilePicker.platform.pickFiles(
          type: fp.FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          withData: true, // Load file bytes in memory
        );

        if (result != null &&
            result.files.isNotEmpty &&
            result.files.first.path != null) {
          setState(() {
            _selectedCV = File(result.files.first.path!);
          });
          return;
        } else if (result != null &&
            result.files.isNotEmpty &&
            result.files.first.bytes != null) {
          // If we have bytes but no path (e.g. on web), save to temporary file
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/${result.files.first.name}');
          await file.writeAsBytes(result.files.first.bytes!);
          setState(() {
            _selectedCV = file;
          });
          return;
        }
      } catch (e) {
        // If file_picker fails, we'll fall through to the next approach
        print('File picker error: $e');
      }

      // Alert user that file selection wasn't successful
      if (mounted) {
        _showErrorSnackbar('Could not select CV file. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick CV: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // ── capture everything that needs BuildContext ────────────
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userService = ServiceHelper.getService<UserService>();

    setState(() => _isLoading = true);

    try {
      // ── build the payload synchronously ─────────────────────
      final profileData = ProfileUtils.prepareProfileData(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        selectedProgramme: _selectedProgramme,
        programmeText: _programmeController.text,
        linkedin: _linkedinController.text,
        masterTitle: _masterTitleController.text,
        studyYear: _studyYear,
        foodPreferences: _foodPreferencesController.text,
      );

      // ── perform the asynchronous work ───────────────────────
      await userService.updateProfileFields(profileData);

      if (_selectedProfileImage != null) {
        setState(() => _isUploading = true);
        await userService.uploadProfilePicture(_selectedProfileImage!);
      }
      if (_selectedCV != null) {
        setState(() => _isUploading = true);
        await userService.uploadCV(_selectedCV!);
      }

      // optional: a single guard after the last await
      if (!mounted) return;

      await auth.refreshUserProfile();

      navigator.pop(true); // use captured navigator
      messenger.showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final List<String> missingFields = currentUser?.getMissingFields() ?? [];
    final bool isProfileComplete = missingFields.isEmpty;

    return PopScope<Object?>(
      // Only allow dismiss if profile is complete
      canPop: isProfileComplete,

      // ── new API ───────────────────────────────────────────────
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // No additional action needed as canPop handles the dismissal
        // logic. Just leave the body empty or keep your comment.
      },
      // ──────────────────────────────────────────────────────────

      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            child: _isLoading || _isUploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(_isUploading ? 'Uploading files...' : 'Loading...'),
                    ],
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isProfileComplete
                                  ? 'Update Your Profile'
                                  : 'Complete Your Profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            // Only show close button if profile is complete
                            if (isProfileComplete)
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                tooltip: 'Close',
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isProfileComplete
                              ? 'Update your profile information anytime.'
                              : 'Please complete the missing fields to activate your profile.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),

                        // Dynamically build form based on missing fields
                        const SizedBox(height: 24),
                        _buildDynamicForm(missingFields),
                        const SizedBox(height: 24),

                        // Dynamic submit button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitForm,
                            child: Text(isProfileComplete
                                ? 'Update Profile'
                                : 'Complete Profile'),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Dynamic form builder that only shows fields that need to be completed
  Widget _buildDynamicForm(List<String> missingFields) {
    final allMissing = missingFields.isEmpty ? false : true;

    // If no missing fields, show all sections for updating
    if (!allMissing) {
      return Column(
        children: [
          ExpansionTile(
            title: const Text('Basic Information'),
            initiallyExpanded: true,
            children: [
              _buildBasicInfoFields(),
            ],
          ),
          ExpansionTile(
            title: const Text('Education'),
            children: [
              _buildEducationFields(),
            ],
          ),
          ExpansionTile(
            title: const Text('Preferences'),
            children: [
              _buildPreferencesFields(),
            ],
          ),
          ExpansionTile(
            title: const Text('Media & Documents (Optional)'),
            children: [
              _buildUploadsFields(),
            ],
          ),
        ],
      );
    }

    // Otherwise, only show sections with missing fields
    return Column(
      children: [
        if (missingFields.contains('First Name') ||
            missingFields.contains('Last Name'))
          ExpansionTile(
            title: const Text('Basic Information'),
            initiallyExpanded: true,
            children: [
              _buildBasicInfoFields(),
            ],
          ),
        if (missingFields.contains('Programme') ||
            missingFields.contains('Master Title') ||
            missingFields.contains('Study Year'))
          ExpansionTile(
            title: const Text('Education'),
            initiallyExpanded: true,
            children: [
              _buildEducationFields(),
            ],
          ),
        if (missingFields.contains('LinkedIn') ||
            missingFields.contains('Food Preferences'))
          ExpansionTile(
            title: const Text('Preferences'),
            initiallyExpanded: true,
            children: [
              _buildPreferencesFields(),
            ],
          ),
        // Always show optional media section but mark as optional
        ExpansionTile(
          title: const Text('Media & Documents (Optional)'),
          children: [
            _buildUploadsFields(),
          ],
        ),
      ],
    );
  }

  // Create separate methods for each section's fields
  Widget _buildBasicInfoFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final bool needsFirstName =
        currentUser?.firstName == null || currentUser!.firstName!.isEmpty;
    final bool needsLastName =
        currentUser?.lastName == null || currentUser!.lastName!.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: ProfileFormComponents.buildBasicInfoFields(
        firstNameController: _firstNameController,
        lastNameController: _lastNameController,
        needsFirstName: needsFirstName,
        needsLastName: needsLastName,
      ),
    );
  }

  Widget _buildEducationFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final bool needsProgramme =
        currentUser?.programme == null || currentUser!.programme!.isEmpty;
    final bool needsMasterTitle =
        currentUser?.masterTitle == null || currentUser!.masterTitle!.isEmpty;
    final bool needsStudyYear = currentUser?.studyYear == null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: ProfileFormComponents.buildEducationFields(
        context: context,
        programmeController: _programmeController,
        masterTitleController: _masterTitleController,
        studyYear: _studyYear,
        selectedProgramme: _selectedProgramme,
        onStudyYearChanged: (int? newValue) {
          setState(() {
            _studyYear = newValue;
          });
        },
        onProgrammeChanged: (Programme? newValue) {
          setState(() {
            _selectedProgramme = newValue;
            if (newValue != null) {
              _programmeController.text = programs
                  .firstWhere(
                      (program) => program['value'] == newValue)['label']
                  .toString();
            }
          });
        },
        needsProgramme: needsProgramme,
        needsMasterTitle: needsMasterTitle,
        needsStudyYear: needsStudyYear,
      ),
    );
  }

  Widget _buildPreferencesFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final bool needsLinkedin =
        currentUser?.linkedin == null || currentUser!.linkedin!.isEmpty;
    final bool needsFoodPreferences = currentUser?.foodPreferences == null ||
        currentUser!.foodPreferences!.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: ProfileFormComponents.buildPreferencesFields(
        linkedinController: _linkedinController,
        foodPreferencesController: _foodPreferencesController,
        needsLinkedin: needsLinkedin,
        needsFoodPreferences: needsFoodPreferences,
      ),
    );
  }

  Widget _buildUploadsFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Profile Media (Optional)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Profile Picture Section
          const Text('Profile Picture',
              style: TextStyle(fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),
          ProfileFormComponents.buildProfilePictureSection(
            selectedProfileImage: _selectedProfileImage,
            onPickImage: _pickProfileImage,
            onDeleteImage: null,
            profilePictureDeleted: _profilePictureDeleted,
            currentProfilePicture: currentUser?.profilePicture,
          ),
          const SizedBox(height: 16),

          // CV Section
          const Text('CV / Resume',
              style: TextStyle(fontWeight: FontWeight.normal)),
          const SizedBox(height: 8),
          ProfileFormComponents.buildCVSection(
            context: context,
            selectedCV: _selectedCV,
            onPickCV: _pickCVFile,
            onDeleteCV: null,
            cvDeleted: _cvDeleted,
            currentCV: currentUser?.cv,
          ),
        ],
      ),
    );
  }
}
