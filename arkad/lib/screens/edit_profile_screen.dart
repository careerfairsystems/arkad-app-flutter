import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';
import '../widgets/profile_completion_dialog.dart'; // Import for Programme enum

class EditProfileScreen extends StatefulWidget {
  final User user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();

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

  final List<int> _studyYearOptions = [1, 2, 3, 4, 5];
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
    _programmeController =
        TextEditingController(text: widget.user.programme ?? '');
    _linkedinController =
        TextEditingController(text: widget.user.linkedin ?? '');
    _masterTitleController =
        TextEditingController(text: widget.user.masterTitle ?? '');
    _foodPreferencesController =
        TextEditingController(text: widget.user.foodPreferences ?? '');

    _studyYear = widget.user.studyYear;

    // Convert string programme to enum if it exists
    if (widget.user.programme != null && widget.user.programme!.isNotEmpty) {
      try {
        _selectedProgramme = PROGRAMS.firstWhere(
          (prog) => prog['label'] == widget.user.programme,
          orElse: () => PROGRAMS[0],
        )['value'] as Programme;
      } catch (e) {
        _selectedProgramme = null;
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick image: $e');
    }
  }

  Future<void> _pickCV() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
        withData: true,
      );

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        setState(() {
          _selectedCV = File(result.files.first.path!);
        });
      }
    } catch (e) {
      _showErrorSnackbar('Failed to pick CV: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      // Prepare the profile data from form fields
      final profileData = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        // Get the label from the selected programme enum
        'programme': _selectedProgramme != null
            ? PROGRAMS.firstWhere(
                    (prog) => prog['value'] == _selectedProgramme)['label']
                as String
            : _programmeController.text.trim(),
        'linkedin': _linkedinController.text.trim(),
        'master_title': _masterTitleController.text.trim(),
        'study_year': _studyYear,
        'food_preferences': _foodPreferencesController.text.trim(),
      };

      // Remove null values to avoid overwriting with null
      profileData.removeWhere(
          (key, value) => value == null || (value is String && value.isEmpty));

      // Update the user profile with the UserService
      await _userService.updateProfileFields(profileData);

      // Upload profile picture if selected
      if (_selectedImage != null) {
        setState(() {
          _isUploading = true;
        });
        await _userService.uploadProfilePicture(_selectedImage!);
      }

      // Upload CV if selected
      if (_selectedCV != null) {
        setState(() {
          _isUploading = true;
        });
        await _userService.uploadCV(_selectedCV!);
      }

      // Refresh the user profile in the auth provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
      _showErrorSnackbar('Failed to update profile: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
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

      // Make the API call
      await _userService.deleteProfilePicture();

      // Refresh user data in provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture removed successfully')),
      );
    } catch (e) {
      // Revert the visual indicator if there was an error
      setState(() {
        _profilePictureDeleted = false;
      });
      _showErrorSnackbar('Failed to remove profile picture: $e');
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

      // Make the API call
      await _userService.deleteCV();

      // Refresh user data in provider
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CV removed successfully')),
      );
    } catch (e) {
      // Revert the visual indicator if there was an error
      setState(() {
        _cvDeleted = false;
      });
      _showErrorSnackbar('Failed to remove CV: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: _isUploading
          ? const Center(
              child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Updating profile...'),
              ],
            ))
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
                          Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _selectedImage != null
                                    ? FileImage(_selectedImage!)
                                    : (!_profilePictureDeleted &&
                                            widget.user.profilePicture !=
                                                null &&
                                            widget
                                                .user.profilePicture!.isNotEmpty
                                        ? NetworkImage(
                                            widget.user.profilePicture!)
                                        : null) as ImageProvider<Object>?,
                                child: (_selectedImage == null &&
                                        (_profilePictureDeleted ||
                                            widget.user.profilePicture ==
                                                null ||
                                            widget
                                                .user.profilePicture!.isEmpty))
                                    ? const Icon(Icons.person, size: 60)
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.camera_alt,
                                        color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (!_profilePictureDeleted &&
                              widget.user.profilePicture != null &&
                              widget.user.profilePicture!.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              label: const Text('Remove Picture',
                                  style: TextStyle(color: Colors.red)),
                              onPressed: _deleteProfilePicture,
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
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),

                    const Text(
                      'Basic Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

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

                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name *',
                        border: OutlineInputBorder(),
                        helperText: 'Required',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'First name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(
                        labelText: 'Last Name *',
                        border: OutlineInputBorder(),
                        helperText: 'Required',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Last name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Education information section
                    const Text(
                      'Education Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<Programme>(
                      decoration: const InputDecoration(
                        labelText: 'Programme *',
                        border: OutlineInputBorder(),
                        helperText: 'Required',
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
                      items: PROGRAMS.map((program) {
                        return DropdownMenuItem<Programme>(
                          value: program['value'] as Programme,
                          child: Text(
                            program['label'] as String,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (Programme? newValue) {
                        setState(() {
                          _selectedProgramme = newValue;
                          if (newValue != null) {
                            _programmeController.text = PROGRAMS
                                .firstWhere((program) =>
                                    program['value'] == newValue)['label']
                                .toString();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _masterTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Master Title *',
                        border: OutlineInputBorder(),
                        helperText: 'Required',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Master title is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Study Year *',
                        border: OutlineInputBorder(),
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
                      items: _studyYearOptions.map((year) {
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

                    // Professional information section
                    const Text(
                      'Professional Information',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _linkedinController,
                      decoration: const InputDecoration(
                        labelText: 'LinkedIn Profile URL *',
                        border: OutlineInputBorder(),
                        helperText:
                            'Required (e.g., linkedin.com/in/yourprofile)',
                        prefixIcon: Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'LinkedIn profile is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _foodPreferencesController,
                      decoration: const InputDecoration(
                        labelText: 'Food Preferences *',
                        border: OutlineInputBorder(),
                        helperText:
                            'Required (allergies, vegetarian, etc. or "None")',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Food preferences are required (put "None" if not applicable)';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // CV management
                    const Text(
                      'CV / Resume',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _selectedCV != null ||
                                    (widget.user.cv != null &&
                                        widget.user.cv!.isNotEmpty)
                                ? Icons.check_circle
                                : Icons.upload_file,
                            color: _selectedCV != null ||
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
                              style: TextStyle(
                                color: _selectedCV != null ||
                                        (!_cvDeleted &&
                                            widget.user.cv != null &&
                                            widget.user.cv!.isNotEmpty)
                                    ? Colors.black
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _pickCV,
                            icon: const Icon(Icons.attach_file),
                            label: Text(widget.user.cv != null &&
                                    widget.user.cv!.isNotEmpty
                                ? 'Change CV'
                                : 'Select CV File'),
                          ),
                        ),
                        if (!_cvDeleted &&
                            widget.user.cv != null &&
                            widget.user.cv!.isNotEmpty)
                          const SizedBox(width: 8),
                        if (!_cvDeleted &&
                            widget.user.cv != null &&
                            widget.user.cv!.isNotEmpty)
                          TextButton.icon(
                            onPressed: _deleteCV,
                            icon: const Icon(Icons.delete, color: Colors.red),
                            label: const Text('Remove',
                                style: TextStyle(color: Colors.red)),
                          ),
                      ],
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
