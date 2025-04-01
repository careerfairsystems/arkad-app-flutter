import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
// Import updated packages
import 'package:path_provider/path_provider.dart';
// We'll still use file_picker but with a fallback approach
import 'package:file_picker/file_picker.dart' as fp;
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/user_service.dart';

// Define the Programme enum
enum Programme {
  Architecture,
  Automotive,
  Automation,
  Biomedical_Engineering,
  Chemical_Engineering,
  Civil_Engineering,
  Computer_Science_Engineering,
  Construction_and_Architecture,
  Construction_and_Railway_Construction,
  Road_and_Traffic_Technology,
  Electrical_Engineering,
  Engineering_Biotechnology,
  Information_and_Communication_Engineering,
  Engineering_Mathematics,
  Engineering_Nanoscience,
  Engineering_Physics,
  Environmental_Engineering,
  Fire_Protection_Engineering,
  Industrial_Design,
  Industrial_Economics_and_Management,
  Surveying,
  Mechanical_engineering,
  Mechanical_Engineering_with_Industrial_Design,
  Risk_Safety_and_Crisis_Management,
}

// Program options
const PROGRAMS = [
  {'label': "Architecture", 'value': Programme.Architecture},
  {'label': "Automotive", 'value': Programme.Automotive},
  {'label': "Automation", 'value': Programme.Automation},
  {
    'label': "Biomedical Engineering",
    'value': Programme.Biomedical_Engineering
  },
  {'label': "Chemical Engineering", 'value': Programme.Chemical_Engineering},
  {'label': "Civil Engineering", 'value': Programme.Civil_Engineering},
  {
    'label': "Computer Science and Engineering",
    'value': Programme.Computer_Science_Engineering
  },
  {
    'label': "Construction and Architecture",
    'value': Programme.Construction_and_Architecture
  },
  {
    'label': "Construction and Railway Construction",
    'value': Programme.Construction_and_Railway_Construction
  },
  {'label': "Traffic and Road", 'value': Programme.Road_and_Traffic_Technology},
  {
    'label': "Electrical Engineering",
    'value': Programme.Electrical_Engineering
  },
  {
    'label': "Engineering Biotechnology",
    'value': Programme.Engineering_Biotechnology
  },
  {
    'label': "Information and Communication Engineering",
    'value': Programme.Information_and_Communication_Engineering
  },
  {
    'label': "Engineering Mathematics",
    'value': Programme.Engineering_Mathematics
  },
  {
    'label': "Engineering Nanoscience",
    'value': Programme.Engineering_Nanoscience
  },
  {'label': "Engineering Physics", 'value': Programme.Engineering_Physics},
  {
    'label': "Environmental Engineering",
    'value': Programme.Environmental_Engineering
  },
  {
    'label': "Fire Protection Engineering",
    'value': Programme.Fire_Protection_Engineering
  },
  {'label': "Industrial Design", 'value': Programme.Industrial_Design},
  {
    'label': "Industrial Engineering and Management",
    'value': Programme.Industrial_Economics_and_Management
  },
  {'label': "Surveying", 'value': Programme.Surveying},
  {
    'label': "Mechanical Engineering",
    'value': Programme.Mechanical_engineering
  },
  {
    'label': "Mechanical Engineering with Technical Design",
    'value': Programme.Mechanical_Engineering_with_Industrial_Design
  },
  {
    'label': "Risk, Safety and Crisis Management",
    'value': Programme.Risk_Safety_and_Crisis_Management
  },
];

class ProfileCompletionDialog extends StatefulWidget {
  const ProfileCompletionDialog({Key? key}) : super(key: key);

  @override
  State<ProfileCompletionDialog> createState() =>
      _ProfileCompletionDialogState();
}

class _ProfileCompletionDialogState extends State<ProfileCompletionDialog> {
  final _formKey = GlobalKey<FormState>();

  // Page controller for multi-step form
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 4; // Updated to include uploads page

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

  // Study year options
  final List<int> _studyYearOptions = [1, 2, 3, 4, 5];

  final ImagePicker _imagePicker = ImagePicker();

  Programme? _selectedProgramme;

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
    if (user.programme != null && user.programme!.isNotEmpty) {
      try {
        _selectedProgramme = PROGRAMS.firstWhere(
          (prog) => prog['label'] == user.programme,
          orElse: () => PROGRAMS[0],
        )['value'] as Programme;
      } catch (e) {
        _selectedProgramme = null;
      }
    }

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

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final userService = UserService();

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
        profileData.removeWhere((key, value) =>
            value == null || (value is String && value.isEmpty));

        // Update the user profile
        await userService.updateProfileFields(profileData);

        // Upload profile picture if selected
        if (_selectedProfileImage != null) {
          setState(() {
            _isUploading = true;
          });
          await userService.uploadProfilePicture(_selectedProfileImage!);
        }

        // Upload CV if selected
        if (_selectedCV != null) {
          setState(() {
            _isUploading = true;
          });
          await userService.uploadCV(_selectedCV!);
        }

        if (mounted) {
          Navigator.of(context).pop(true); // Return success
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update profile: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isUploading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUser = authProvider.user;
    final List<String> missingFields = currentUser?.getMissingFields() ?? [];
    final bool isProfileComplete = missingFields.isEmpty;

    return WillPopScope(
      // Only allow dismiss if profile is complete
      onWillPop: () async => isProfileComplete,
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
            title: const Text('Media & Documents'),
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
        if (missingFields.contains('Profile Picture') ||
            missingFields.contains('CV'))
          ExpansionTile(
            title: const Text('Media & Documents'),
            initiallyExpanded: true,
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
      child: Column(
        children: [
          if (needsFirstName)
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
          if (needsFirstName) const SizedBox(height: 16),

          if (needsLastName)
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

          // Show message if all fields in this section are completed
          if (!needsFirstName && !needsLastName)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'Your basic information is complete. You can update it if needed.'),
            ),
        ],
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
      child: Column(
        children: [
          if (needsProgramme) ...[
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
              items: PROGRAMS.map((program) {
                return DropdownMenuItem<Programme>(
                  value: program['value'] as Programme,
                  child: Text(program['label'] as String),
                );
              }).toList(),
              onChanged: (Programme? newValue) {
                setState(() {
                  _selectedProgramme = newValue;
                  if (newValue != null) {
                    _programmeController.text = PROGRAMS
                        .firstWhere(
                            (program) => program['value'] == newValue)['label']
                        .toString();
                  }
                });
              },
            ),
            const SizedBox(height: 16),
          ],

          if (needsMasterTitle) ...[
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
          ],

          if (needsStudyYear) ...[
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
          ],

          // Show message if all fields in this section are completed
          if (!needsProgramme && !needsMasterTitle && !needsStudyYear)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'Your education information is complete. You can update it if needed.'),
            ),
        ],
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
      child: Column(
        children: [
          if (needsLinkedin) ...[
            TextFormField(
              controller: _linkedinController,
              decoration: const InputDecoration(
                labelText: 'LinkedIn Profile URL *',
                border: OutlineInputBorder(),
                helperText: 'Required (e.g., linkedin.com/in/yourprofile)',
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
          ],

          if (needsFoodPreferences) ...[
            TextFormField(
              controller: _foodPreferencesController,
              decoration: const InputDecoration(
                labelText: 'Food Preferences *',
                border: OutlineInputBorder(),
                helperText: 'Required (allergies, vegetarian, etc.)',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Food preferences are required (put "None" if not applicable)';
                }
                return null;
              },
            ),
          ],

          // Show message if all fields in this section are completed
          if (!needsLinkedin && !needsFoodPreferences)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'Your preferences are complete. You can update them if needed.'),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadsFields() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.user;
    final bool needsProfilePicture = currentUser?.profilePicture == null ||
        currentUser!.profilePicture!.isEmpty;
    final bool needsCV = currentUser?.cv == null || currentUser!.cv!.isEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        children: [
          if (needsProfilePicture) ...[
            const Text('Profile Picture *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 150,
              width: 150,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(75),
              ),
              child: _selectedProfileImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(75),
                      child:
                          Image.file(_selectedProfileImage!, fit: BoxFit.cover),
                    )
                  : const Icon(Icons.person, size: 80),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickProfileImage,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Select Profile Picture'),
            ),
            const SizedBox(height: 16),
          ],

          if (needsCV) ...[
            const Text('CV / Resume *',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _selectedCV != null
                        ? Icons.check_circle
                        : Icons.upload_file,
                    color: _selectedCV != null ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _selectedCV != null
                          ? 'Selected: ${_selectedCV!.path.split('/').last}'
                          : 'No CV selected yet (PDF format)',
                      style: TextStyle(
                        color: _selectedCV != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _pickCVFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Select CV File'),
            ),
          ],

          // Show message if all fields in this section are completed
          if (!needsProfilePicture && !needsCV)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                  'Your profile picture and CV are already uploaded. You can update them if needed.'),
            ),
        ],
      ),
    );
  }
}
