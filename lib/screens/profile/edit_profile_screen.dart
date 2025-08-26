import 'dart:io';

import 'package:arkad/models/programme.dart';
import 'package:arkad/view_models/profile_model.dart';
import 'package:arkad_api/arkad_api.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../utils/profile_utils.dart';
import '../../widgets/profile/profile_form_components.dart';

class EditProfileScreen extends StatefulWidget {
  final ProfileSchema profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

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

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _emailController = TextEditingController(text: widget.profile.email);
    _firstNameController = TextEditingController(
      text: widget.profile.firstName,
    );
    _lastNameController = TextEditingController(text: widget.profile.lastName);
    _programmeController = TextEditingController(
      text: widget.profile.programme ?? '',
    );

    // Extract LinkedIn username from URL if it exists
    String linkedinUsername = '';
    if (widget.profile.linkedin != null &&
        widget.profile.linkedin!.isNotEmpty) {
      final url = widget.profile.linkedin!;
      if (url.contains('linkedin.com/in/')) {
        final parts = url.split('/in/');
        if (parts.length > 1) {
          linkedinUsername = parts[1].split('/').first.split('?').first;
        }
      } else {
        linkedinUsername = widget.profile.linkedin!;
      }
    }

    _linkedinController = TextEditingController(text: linkedinUsername);

    _masterTitleController = TextEditingController(
      text: widget.profile.masterTitle ?? '',
    );
    _foodPreferencesController = TextEditingController(
      text: widget.profile.foodPreferences ?? '',
    );

    _studyYear = widget.profile.studyYear;

    // Convert string programme to enum if it exists
    _selectedProgramme = ProfileUtils.programmeStringToEnum(
      widget.profile.programme,
    );
  }

  Future<void> _pickImage() async {
    final File? image = await ProfileUtils.pickProfileImage(
      context: context,
      imagePicker: _imagePicker,
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
    final File? cv = await ProfileUtils.pickCVFile(context: context);

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
    final profileProvider = GetIt.I<ProfileModel>();

    try {
      // Generate profile data
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

      // Update profile using the centralized provider
      final success = await profileProvider.updateProfile(
        profileData: profileData,
        profilePicture: _selectedImage,
        deleteProfilePicture: _profilePictureDeleted,
        cv: _selectedCV,
        deleteCV: _cvDeleted,
      );

      if (success) {
        // Refresh user data
        // await auth.refreshUserProfile(); FIX?

        // Bail out if the widget got disposed while we were waiting
        if (!mounted) return;

        // Return to previous screen
        navigator.pop();
        messenger.showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      } else if (profileProvider.error != null && mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${profileProvider.error}'),
          ),
        );
      }
    } catch (e) {
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
    final profileProvider = Provider.of<ProfileModel>(context);
    final bool isLoading =
        profileProvider.isLoading || profileProvider.isUploading;

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
                                  widget.profile.profilePicture,
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
                      if (profileProvider.error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.red.shade100,
                          child: Text(
                            profileProvider.error!,
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
                                  programs
                                      .firstWhere(
                                        (program) =>
                                            program['value'] == newValue,
                                      )['label']
                                      .toString();
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
                        currentCV: widget.profile.cv,
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
