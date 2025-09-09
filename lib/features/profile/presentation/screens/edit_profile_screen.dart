import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../../../services/service_locator.dart';
import '../../../../shared/infrastructure/services/file_service.dart';
import '../../domain/entities/programme.dart';
import '../view_models/profile_view_model.dart';
import '../widgets/profile_form_components.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _programmeController;
  late TextEditingController _linkedinController;
  late TextEditingController _masterTitleController;
  late TextEditingController _foodPreferencesController;

  int? _studyYear;
  Programme? _selectedProgramme;

  File? _selectedImage;
  File? _selectedCV;

  // Track local UI state
  bool _profilePictureDeleted = false;
  bool _cvDeleted = false;

  // View model reference
  late ProfileViewModel _profileViewModel;

  @override
  void initState() {
    super.initState();
    _profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    _profileViewModel.addListener(_onProfileChanged);
    _initializeControllers();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _initializeControllers() {
    final profile = _profileViewModel.currentProfile;
    
    _emailController = TextEditingController(text: profile?.email ?? '');
    _firstNameController = TextEditingController(
      text: profile?.firstName ?? '',
    );
    _lastNameController = TextEditingController(text: profile?.lastName ?? '');
    _programmeController = TextEditingController(
      text: profile?.programme?.name ?? '',
    );

    // Extract LinkedIn username from URL if it exists
    String linkedinUsername = '';
    if (profile?.linkedin != null &&
        profile!.linkedin!.isNotEmpty) {
      final url = profile.linkedin!;
      if (url.contains('linkedin.com/in/')) {
        final parts = url.split('/in/');
        if (parts.length > 1) {
          linkedinUsername = parts[1].split('/').first.split('?').first;
        }
      } else {
        linkedinUsername = profile.linkedin!;
      }
    }

    _linkedinController = TextEditingController(text: linkedinUsername);

    _masterTitleController = TextEditingController(
      text: profile?.masterTitle ?? '',
    );
    _foodPreferencesController = TextEditingController(
      text: profile?.foodPreferences ?? '',
    );

    _studyYear = profile?.studyYear;

    // Convert enum programme to selected value if it exists
    _selectedProgramme = profile?.programme;
  }

  Future<void> _pickImage() async {
    final fileService = serviceLocator<FileService>();
    final File? image = await fileService.pickProfileImage(
      context: context,
    );

    if (image != null) {
      setState(() {
        _selectedImage = image;
        _profilePictureDeleted =
            false; // Reset deletion flag if new image selected
      });
    }
  }

  Future<void> _pickCV() async {
    final fileService = serviceLocator<FileService>();
    final File? cv = await fileService.pickCVFile(context: context);

    if (cv != null) {
      setState(() {
        _selectedCV = cv;
        _cvDeleted = false; // Reset deletion flag if new CV selected
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Get references to providers and other objects
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    final currentProfile = profileViewModel.currentProfile;

    try {
      if (currentProfile == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No profile data available')),
        );
        return;
      }

      // Create updated profile data
      final updatedProfile = currentProfile.copyWith(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        programme: _selectedProgramme,
        linkedin: _linkedinController.text.isEmpty ? null : _linkedinController.text,
        masterTitle: _masterTitleController.text.isEmpty ? null : _masterTitleController.text,
        studyYear: _studyYear,
        foodPreferences: _foodPreferencesController.text,
      );

      // Update profile using clean architecture
      bool success = await profileViewModel.updateProfile(updatedProfile);
      
      // Handle file uploads if needed
      if (success && _selectedImage != null) {
        success = await profileViewModel.uploadProfilePicture(_selectedImage!);
      }
      
      if (success && _selectedCV != null) {
        success = await profileViewModel.uploadCV(_selectedCV!);
      }
      
      // Handle file deletions if needed
      if (success && _profilePictureDeleted) {
        await profileViewModel.deleteProfilePicture();
      }
      
      if (success && _cvDeleted) {
        await profileViewModel.deleteCV();
      }

      if (success) {
        // Bail out if the widget got disposed while we were waiting
        if (!mounted) return;

        // Return to previous screen
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else if (profileViewModel.error != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${profileViewModel.error!.userMessage}'),
          ),
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    }
  }

  void _deleteProfilePicture() {
    setState(() {
      _profilePictureDeleted = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile picture will be removed when you save'),
        ),
      );
    }
  }

  void _deleteCV() {
    setState(() {
      _cvDeleted = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV will be removed when you save')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profileViewModel.currentProfile;
    final isLoading = _profileViewModel.isLoading;
    final error = _profileViewModel.error;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body:
          isLoading
              ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Updating profile...'),
                  ],
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile picture section
                      Center(
                        child: Column(
                          children: [
                            ProfileFormComponents.buildProfilePictureSection(
                              selectedProfileImage: _selectedImage,
                              onPickImage: _pickImage,
                              onDeleteImage: _deleteProfilePicture,
                              profilePictureDeleted: _profilePictureDeleted,
                              currentProfilePicture:
                                  profile?.profilePictureUrl,
                            ),
                            const Text(
                              'Profile Picture (Optional)',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Error display
                      if (error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.red.shade100,
                          child: Text(
                            error.userMessage,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.red.shade800),
                          ),
                        ),

                      const Text(
                        'Basic Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Email field (always readonly)
                      TextFormField(
                        controller: _emailController,
                        readOnly: true, // Email cannot be changed
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          helperText: 'Email cannot be changed',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Basic information fields
                      ProfileFormComponents.buildBasicInfoFields(
                        firstNameController: _firstNameController,
                        lastNameController: _lastNameController,
                      ),

                      const SizedBox(height: 24),

                      // Education information section
                      const Text(
                        'Education Information (Optional)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      ProfileFormComponents.buildEducationFields(
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
                              _programmeController.text =
                                  availableProgrammes
                                      .firstWhere(
                                        (program) =>
                                            program.value == newValue,
                                      ).label;
                            }
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // Professional information section
                      const Text(
                        'Additional Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Food preferences are required, other fields are optional',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      ProfileFormComponents.buildPreferencesFields(
                        linkedinController: _linkedinController,
                        foodPreferencesController: _foodPreferencesController,
                      ),

                      const SizedBox(height: 24),

                      // CV management section
                      const Text(
                        'CV / Resume (Optional)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      ProfileFormComponents.buildCVSection(
                        context: context,
                        selectedCV: _selectedCV,
                        onPickCV: _pickCV,
                        onDeleteCV: _deleteCV,
                        cvDeleted: _cvDeleted,
                        currentCV: profile?.cvUrl,
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _profileViewModel.removeListener(_onProfileChanged);
    _emailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _programmeController.dispose();
    _linkedinController.dispose();
    _masterTitleController.dispose();
    _foodPreferencesController.dispose();
    super.dispose();
  }
}
