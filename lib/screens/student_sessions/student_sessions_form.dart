import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/profile/domain/entities/programme.dart';
import '../../shared/infrastructure/services/file_service.dart';
import '../../services/service_locator.dart';
import '../../features/auth/presentation/view_models/auth_view_model.dart';
import '../../features/profile/presentation/view_models/profile_view_model.dart';

class StudentSessionFormScreen extends StatefulWidget {
  final String id; // Company ID

  const StudentSessionFormScreen({super.key, required this.id});

  @override
  State<StudentSessionFormScreen> createState() =>
      _StudentSessionFormScreenState();
}

class _StudentSessionFormScreenState extends State<StudentSessionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers and state variables
  Programme? _selectedProgramme;
  int? _studyYear;
  File? _cvFile;
  File? _motivationFile;

  String? _initialCvFileName; // To store CV filename from user's profile
  bool _isLoading = true; // For loading initial data

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
    final profileViewModel = Provider.of<ProfileViewModel>(context, listen: false);
    final currentUser = authViewModel.currentUser;

    if (currentUser != null) {
      // Load detailed profile data for form pre-population
      await profileViewModel.loadProfile();
      final profile = profileViewModel.currentProfile;
      
      if (profile != null) {
        _selectedProgramme = profile.programme;
        _studyYear = profile.studyYear;
        
        if (profile.cvUrl != null) {
          _initialCvFileName = profile.cvUrl!.split('/').last;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickCV() async {
    try {
      final pickedFile = await serviceLocator<FileService>().pickCVFile(
        context: context,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Select CV (PDF)', // Corrected dialog title
      );
      if (pickedFile != null) {
        setState(() {
          _cvFile = pickedFile;
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

  Future<void> _pickMotivationLetter() async {
    // Assuming motivation letter is also a PDF, similar to CV
    try {
      final pickedFile = await serviceLocator<FileService>().pickCVFile(
        context: context,
        allowedExtensions: ['pdf'],
        dialogTitle: 'Select Motivation Letter (PDF)',
      );
      if (pickedFile != null) {
        setState(() {
          _motivationFile = pickedFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking motivation letter: $e')),
        );
      }
    }
  }

  Widget _buildCVSection() {
    bool hasCvOnFile =
        _initialCvFileName != null && _initialCvFileName!.isNotEmpty;
    bool hasPickedNewCv = _cvFile != null;
    bool cvExists = hasPickedNewCv || hasCvOnFile;

    String cvText;
    if (hasPickedNewCv) {
      cvText = 'Selected: ${_cvFile!.path.split('/').last}';
    } else if (hasCvOnFile) {
      cvText = 'Current: $_initialCvFileName';
    } else {
      cvText = 'No CV selected';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CV / Resume (PDF) *', // Marked as required, adjust if optional
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                cvExists ? Icons.check_circle : Icons.upload_file,
                color: cvExists ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cvText,
                  style: Theme.of(context).textTheme.bodyMedium,
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
                label: Text(cvExists ? 'Change CV' : 'Upload CV'),
              ),
            ),
            if (cvExists) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _cvFile = null;
                    _initialCvFileName =
                        null; // Clear initial CV reference as well
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
        // CV validation is now primarily handled in the submit button's logic
      ],
    );
  }

  Widget _buildMotivationLetterSection() {
    // Similar to ProfileFormComponents.buildCVSection but for motivation letter
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Motivational Letter (Optional, PDF)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _motivationFile != null
                    ? Icons.check_circle
                    : Icons.upload_file,
                color: _motivationFile != null ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _motivationFile != null
                      ? 'Selected: ${_motivationFile!.path.split('/').last}'
                      : 'No letter selected',
                  style: Theme.of(context).textTheme.bodyMedium,
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
                onPressed: _pickMotivationLetter,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  _motivationFile != null ? 'Change Letter' : 'Upload Letter',
                ),
              ),
            ),
            if (_motivationFile != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _motivationFile = null;
                  });
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Student Session Application')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Student Session Application')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Applying for session with Company ID: ${widget.id}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Programme
                DropdownButtonFormField<Programme>(
                  // Changed to Programme
                  decoration: const InputDecoration(
                    labelText: 'Programme *',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 16,
                    ),
                  ),
                  value: _selectedProgramme, // Directly use Programme? type
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
                      availableProgrammes.map((program) {
                        return DropdownMenuItem<Programme>(
                          value: program.value,
                          child: Text(
                            program.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                  onChanged: (Programme? newValue) {
                    // Changed to Programme?
                    setState(() {
                      _selectedProgramme = newValue;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Study Year
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(
                    labelText: 'Study Year *',
                    border: OutlineInputBorder(),
                  ),
                  value: _studyYear, // Pre-filled by _loadUserData
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
                const SizedBox(height: 20),

                // CV Upload
                _buildCVSection(), // Uses updated logic for pre-fill and display
                const SizedBox(height: 20),

                // Motivational Letter File Upload
                _buildMotivationLetterSection(),
                const SizedBox(height: 30),

                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 50,
                        vertical: 15,
                      ),
                    ),
                    onPressed: () {
                      // Manually trigger re-evaluation for any conditional UI if needed
                      setState(() {});
                      if (_formKey.currentState!.validate()) {
                        bool isCvProvided =
                            _cvFile != null ||
                            (_initialCvFileName != null &&
                                _initialCvFileName!.isNotEmpty);

                        if (!isCvProvided) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please upload your CV.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return; // Stop submission if CV is missing
                        }

                        // Process data
                        // _selectedProgramme, _studyYear are already set
                        // For CV:
                        // If _cvFile is not null, a new CV has been selected.
                        // Else if _initialCvFileName is not null, the user is proceeding with their existing CV.
                        // If both are null (though validation should prevent this if CV is required), it's an issue.

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Application Submitted (Simulated)'),
                          ),
                        );
                        // Potentially pop or navigate away
                      }
                    },
                    child: const Text('Submit Application'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
