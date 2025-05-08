import 'dart:io';
import 'package:flutter/material.dart';
import '../../models/programme.dart';

class ProfileFormComponents {
  static Widget buildBasicInfoFields({
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    bool readOnlyMode = false,
    bool needsFirstName = true,
    bool needsLastName = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsFirstName) ...[
          TextFormField(
            controller: firstNameController,
            readOnly: readOnlyMode,
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
        ],

        if (needsLastName) ...[
          TextFormField(
            controller: lastNameController,
            readOnly: readOnlyMode,
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
          if (needsFirstName || needsLastName) const SizedBox(height: 16),
        ],

        // Show message if all fields in this section are provided but not needed
        if (!needsFirstName && !needsLastName)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Your basic information is complete. You can update it if needed.',
            ),
          ),
      ],
    );
  }

  static Widget buildEducationFields({
    required BuildContext context,
    required TextEditingController programmeController,
    required TextEditingController masterTitleController,
    required int? studyYear,
    required Function(int?) onStudyYearChanged,
    required Programme? selectedProgramme,
    required Function(Programme?) onProgrammeChanged,
    bool readOnlyMode = false,
    bool needsProgramme = true,
    bool needsMasterTitle = true,
    bool needsStudyYear = true,
  }) {
    final List<int> studyYearOptions = [1, 2, 3, 4, 5];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsProgramme) ...[
          DropdownButtonFormField<Programme>(
            decoration: const InputDecoration(
              labelText: 'Programme *',
              border: OutlineInputBorder(),
              helperText: 'Required',
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
            ),
            value: selectedProgramme,
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
            onChanged: readOnlyMode ? null : onProgrammeChanged,
          ),
          const SizedBox(height: 16),
        ],

        if (needsMasterTitle) ...[
          TextFormField(
            controller: masterTitleController,
            readOnly: readOnlyMode,
            decoration: const InputDecoration(
              labelText: 'Master Title', // Removed asterisk for optional field
              border: OutlineInputBorder(),
              helperText: 'Optional',
            ),
            // No validator required since field is optional
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
            value: studyYear,
            hint: const Text('Select your study year'),
            validator: (value) {
              if (value == null) {
                return 'Study year is required';
              }
              return null;
            },
            items:
                studyYearOptions.map((year) {
                  return DropdownMenuItem<int>(
                    value: year,
                    child: Text('Year $year'),
                  );
                }).toList(),
            onChanged: readOnlyMode ? null : onStudyYearChanged,
          ),
        ],

        // Show message if all fields in this section are provided but not needed
        if (!needsProgramme && !needsMasterTitle && !needsStudyYear)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Your education information is complete. You can update it if needed.',
            ),
          ),
      ],
    );
  }

  static Widget buildPreferencesFields({
    required TextEditingController linkedinController,
    required TextEditingController foodPreferencesController,
    bool readOnlyMode = false,
    bool needsLinkedin = true,
    bool needsFoodPreferences = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (needsLinkedin) ...[
          TextFormField(
            controller: linkedinController,
            readOnly: readOnlyMode,
            decoration: const InputDecoration(
              labelText: 'LinkedIn Username',
              border: OutlineInputBorder(),
              helperText:
                  'Optional - Just enter your username, not the full URL',
              prefixIcon: Icon(Icons.link),
            ),
            // No validator required since field is optional
          ),
          const SizedBox(height: 16),
        ],

        if (needsFoodPreferences) ...[
          TextFormField(
            controller: foodPreferencesController,
            readOnly: readOnlyMode,
            decoration: const InputDecoration(
              labelText: 'Food Preferences *',
              border: OutlineInputBorder(),
              helperText: 'Required (allergies, vegetarian, etc. or "None")',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Food preferences are required (put "None" if not applicable)';
              }
              return null;
            },
          ),
        ],

        // Show message if all fields in this section are provided but not needed
        if (!needsLinkedin && !needsFoodPreferences)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Your preferences are complete. You can update them if needed.',
            ),
          ),
      ],
    );
  }

  static Widget buildProfilePictureSection({
    required File? selectedProfileImage,
    required Function() onPickImage,
    required Function()? onDeleteImage,
    required bool profilePictureDeleted,
    required String? currentProfilePicture,
  }) {
    return Column(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage:
                  selectedProfileImage != null
                      ? FileImage(selectedProfileImage)
                      : (!profilePictureDeleted &&
                                  currentProfilePicture != null &&
                                  currentProfilePicture.isNotEmpty
                              ? NetworkImage(currentProfilePicture)
                              : null)
                          as ImageProvider<Object>?,
              child:
                  (selectedProfileImage == null &&
                          (profilePictureDeleted ||
                              currentProfilePicture == null ||
                              currentProfilePicture.isEmpty))
                      ? const Icon(Icons.person, size: 60)
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: onPickImage,
                ),
              ),
            ),
          ],
        ),
        if (!profilePictureDeleted &&
            currentProfilePicture != null &&
            currentProfilePicture.isNotEmpty &&
            onDeleteImage != null)
          TextButton.icon(
            icon: const Icon(Icons.delete, color: Colors.red),
            label: const Text(
              'Remove Picture',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: onDeleteImage,
          ),
      ],
    );
  }

  static Widget buildCVSection({
    required BuildContext context,
    required File? selectedCV,
    required Function() onPickCV,
    required Function()? onDeleteCV,
    required bool cvDeleted,
    required String? currentCV,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                selectedCV != null ||
                        (!cvDeleted &&
                            currentCV != null &&
                            currentCV.isNotEmpty)
                    ? Icons.check_circle
                    : Icons.upload_file,
                color:
                    selectedCV != null ||
                            (!cvDeleted &&
                                currentCV != null &&
                                currentCV.isNotEmpty)
                        ? Colors.green
                        : Colors.grey,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  selectedCV != null
                      ? 'Selected: ${selectedCV.path.split('/').last}'
                      : (cvDeleted
                          ? 'No CV selected yet (PDF format)'
                          : (currentCV != null && currentCV.isNotEmpty
                              ? 'Current: ${currentCV.split('/').last}'
                              : 'No CV selected yet (PDF format)')),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('CV / Resume (Optional)', style: TextStyle(fontSize: 12)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onPickCV,
                icon: const Icon(Icons.attach_file),
                label: Text(
                  currentCV != null && currentCV.isNotEmpty
                      ? 'Change CV'
                      : 'Select CV File',
                ),
              ),
            ),
            if (!cvDeleted &&
                currentCV != null &&
                currentCV.isNotEmpty &&
                onDeleteCV != null) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onDeleteCV,
                icon: const Icon(Icons.delete, color: Colors.red),
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
}
