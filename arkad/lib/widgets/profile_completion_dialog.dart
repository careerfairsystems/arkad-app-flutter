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
    return WillPopScope(
      // Prevent dialog from closing when back button is pressed
      onWillPop: () async => false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Don't dismiss on tap outside
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
                              'Complete Your Profile',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            // Close button
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.of(context).pop(false),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help companies find you by completing your profile information.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height:
                              400, // Increased height for more content visibility
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            children: [
                              SingleChildScrollView(
                                  child: _buildBasicInfoPage()),
                              SingleChildScrollView(
                                  child: _buildEducationPage()),
                              SingleChildScrollView(
                                  child: _buildPreferencesPage()),
                              SingleChildScrollView(child: _buildUploadsPage()),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildPageIndicator(),
                        const SizedBox(height: 16),
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(
            labelText: 'First Name',
            border: OutlineInputBorder(),
          ),
          // Removed validator as it's now optional
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(
            labelText: 'Last Name',
            border: OutlineInputBorder(),
          ),
          // Removed validator as it's now optional
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _linkedinController,
          decoration: const InputDecoration(
            labelText: 'LinkedIn URL',
            border: OutlineInputBorder(),
            hintText: 'https://linkedin.com/in/yourprofile',
          ),
        ),
      ],
    );
  }

  Widget _buildEducationPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Education Details',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),

        // Programme dropdown
        DropdownButtonFormField<Programme>(
          value: _selectedProgramme,
          decoration: const InputDecoration(
            labelText: 'Programme',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Select your programme'),
          isExpanded: true,
          items: PROGRAMS.map((program) {
            return DropdownMenuItem<Programme>(
              value: program['value'] as Programme,
              child: Text(program['label'] as String),
            );
          }).toList(),
          onChanged: (Programme? value) {
            setState(() {
              _selectedProgramme = value;
              if (value != null) {
                // Update the text controller for consistency
                final programLabel = PROGRAMS.firstWhere(
                  (prog) => prog['value'] == value,
                  orElse: () => {'label': ''},
                )['label'] as String;
                _programmeController.text = programLabel;
              }
            });
          },
        ),

        const SizedBox(height: 16),
        TextFormField(
          controller: _masterTitleController,
          decoration: const InputDecoration(
            labelText: 'Master Title',
            border: OutlineInputBorder(),
            hintText: 'e.g., MSc in Data Science',
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          value: _studyYear,
          decoration: const InputDecoration(
            labelText: 'Study Year',
            border: OutlineInputBorder(),
          ),
          items: [null, ..._studyYearOptions].map((int? year) {
            return DropdownMenuItem<int>(
              value: year,
              child: Text(year == null ? 'Select Study Year' : 'Year $year'),
            );
          }).toList(),
          onChanged: (int? value) {
            setState(() {
              _studyYear = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preferences', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),
        TextFormField(
          controller: _foodPreferencesController,
          decoration: const InputDecoration(
            labelText: 'Food Preferences',
            border: OutlineInputBorder(),
            hintText: 'e.g., Vegetarian, Vegan, Gluten-free, etc.',
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Text(
          'Completing your profile helps companies find you and match you with opportunities.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildUploadsPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Upload Documents',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 16),

        // Profile Picture Upload
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Picture',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Center(
                  child: _selectedProfileImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                            _selectedProfileImage!,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.grey[600],
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickProfileImage,
                    icon: const Icon(Icons.photo_library),
                    label: Text(_selectedProfileImage != null
                        ? 'Change Picture'
                        : 'Select Picture'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // CV Upload
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CV / Resume',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                if (_selectedCV != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.description, color: Colors.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedCV!.path.split('/').last,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Text('No file selected'),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _pickCVFile,
                    icon: const Icon(Icons.upload_file),
                    label:
                        Text(_selectedCV != null ? 'Change File' : 'Upload CV'),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        Text(
          'Uploading your CV makes it easier for recruiters to find you.',
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) {
        return Container(
          width: 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
          ),
        );
      }),
    );
  }

  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_currentPage > 0)
          TextButton(
            onPressed: _previousPage,
            child: const Text('Previous'),
          )
        else
          const SizedBox(width: 80),
        if (_currentPage < _totalPages - 1)
          ElevatedButton(
            onPressed: _nextPage,
            child: const Text('Next'),
          )
        else
          ElevatedButton(
            onPressed: _submitForm,
            child: const Text('Save Profile'),
          ),
      ],
    );
  }
}
