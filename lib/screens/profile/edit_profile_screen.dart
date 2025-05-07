import 'dart:io';

import 'package:arkad/services/user_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../utils/profile_utils.dart';
import '../../utils/service_helper.dart';
import '../../widgets/profile_completion_dialog.dart';
import '../../widgets/profile_form_components.dart';

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = ServiceHelper.getService<UserService>();

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
  bool _isUploading = false;
  String? _error;

  final ImagePicker _imagePicker = ImagePicker();

  // Add these flags to track local UI state
  bool _profilePictureDeleted = false;
  bool _cvDeleted = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.user.email);
    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _programmeController = TextEditingController(
      text: widget.user.programme ?? '',
    );
    _linkedinController = TextEditingController(
      text: widget.user.linkedin ?? '',
    );
    _masterTitleController = TextEditingController(
      text: widget.user.masterTitle ?? '',
    );
    _foodPreferencesController = TextEditingController(
      text: widget.user.foodPreferences ?? '',
    );

    _studyYear = widget.user.studyYear;

    // Convert string programme to enum if it exists
    _selectedProgramme = ProfileUtils.programmeStringToEnum(
      widget.user.programme,
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

    // #1 capture references that don’t change
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
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

      await _userService.updateProfileFields(profileData);
      if (_selectedImage != null) {
        await _userService.uploadProfilePicture(_selectedImage!);
      } else if (_profilePictureDeleted) {
        await _userService.deleteProfilePicture();
      }

      if (_selectedCV != null) {
        await _userService.uploadCV(_selectedCV!);
      } else if (_cvDeleted) {
        await _userService.deleteCV();
      }

      await auth.refreshUserProfile();

      // #2 bail out if the widget got disposed while we were waiting
      if (!mounted) return;

      navigator.pop(); // uses captured Navigator
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
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _deleteProfilePicture() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Immediately update local state for visual feedback
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
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _deleteCV() async {
    try {
      setState(() {
        _isUploading = true;
      });

      // Immediately update local state for visual feedback
      setState(() {
        _cvDeleted = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CV will be removed when you save')),
        );
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body:
          _isUploading
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
                      // Profile picture section (now optional)
                      Center(
                        child: Column(
                          children: [
                            ProfileFormComponents.buildProfilePictureSection(
                              selectedProfileImage: _selectedImage,
                              onPickImage: _pickImage,
                              onDeleteImage: _deleteProfilePicture,
                              profilePictureDeleted: _profilePictureDeleted,
                              currentProfilePicture: widget.user.profilePicture,
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
                      if (_error != null)
                        Container(
                          padding: const EdgeInsets.all(8),
                          margin: const EdgeInsets.only(bottom: 16),
                          color: Colors.red.shade100,
                          child: Text(
                            _error!,
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
                        'Education Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fields marked with * are required',
                        style: TextStyle(fontSize: 12),
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
                        'Professional Information',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Fields marked with * are required',
                        style: TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      ProfileFormComponents.buildPreferencesFields(
                        linkedinController: _linkedinController,
                        foodPreferencesController: _foodPreferencesController,
                      ),

                      const SizedBox(height: 24),

                      // CV management (now optional)
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
                        currentCV: widget.user.cv,
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateProfile,
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
