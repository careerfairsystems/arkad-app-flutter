import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/presentation/themes/arkad_theme.dart';
import '../../domain/entities/programme.dart';

class ProfileFormComponents {
  static Widget buildBasicInfoFields({
    required TextEditingController firstNameController,
    required TextEditingController lastNameController,
    bool readOnlyMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  static Widget buildEducationFields({
    required BuildContext context,
    required TextEditingController programmeController,
    required TextEditingController masterTitleController,
    required int? studyYear,
    required Programme? selectedProgramme,
    required Function(int?) onStudyYearChanged,
    required Function(Programme?) onProgrammeChanged,
    bool readOnlyMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Programme dropdown
        DropdownButtonFormField<Programme>(
          decoration: const InputDecoration(
            labelText: 'Programme',
            border: OutlineInputBorder(),
            helperText: 'Optional',
          ),
          value: selectedProgramme,
          hint: const Text('Select your programme'),
          items:
              availableProgrammes.map((program) {
                return DropdownMenuItem<Programme>(
                  value: program.value,
                  child: Text(
                    program.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }).toList(),
          onChanged: readOnlyMode ? null : onProgrammeChanged,
        ),
        const SizedBox(height: 16),

        // Study year dropdown
        DropdownButtonFormField<int>(
          decoration: const InputDecoration(
            labelText: 'Study Year',
            border: OutlineInputBorder(),
            helperText: 'Optional',
          ),
          value: studyYear,
          hint: const Text('Select your study year'),
          items:
              [1, 2, 3, 4, 5].map((year) {
                return DropdownMenuItem<int>(
                  value: year,
                  child: Text('Year $year'),
                );
              }).toList(),
          onChanged: readOnlyMode ? null : onStudyYearChanged,
        ),
        const SizedBox(height: 16),

        // Master title field
        TextFormField(
          controller: masterTitleController,
          readOnly: readOnlyMode,
          decoration: const InputDecoration(
            labelText: 'Master Title',
            border: OutlineInputBorder(),
            helperText: 'Optional',
          ),
        ),
      ],
    );
  }

  static Widget buildPreferencesFields({
    required TextEditingController linkedinController,
    required TextEditingController foodPreferencesController,
    bool readOnlyMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: linkedinController,
          readOnly: readOnlyMode,
          decoration: const InputDecoration(
            labelText: 'LinkedIn',
            hintText: 'e.g., yourname or linkedin.com/in/yourname',
            border: OutlineInputBorder(),
            helperText:
                'Optional - Enter your LinkedIn username or full profile URL',
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: foodPreferencesController,
          readOnly: readOnlyMode,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Food Preferences',
            hintText: 'e.g., Vegetarian, allergic to nuts, etc. (Optional)',
            border: OutlineInputBorder(),
            helperText: 'Optional - Leave empty if none',
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
                  color: ArkadColors.arkadTurkos,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.camera_alt, color: ArkadColors.white),
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
            icon: const Icon(Icons.delete, color: ArkadColors.lightRed),
            label: const Text(
              'Remove Picture',
              style: TextStyle(color: ArkadColors.lightRed),
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
            border: Border.all(color: ArkadColors.lightGray),
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
                        ? ArkadColors.arkadGreen
                        : ArkadColors.gray,
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
                icon: const Icon(Icons.attach_file, color: ArkadColors.white),
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
                icon: const Icon(Icons.delete, color: ArkadColors.lightRed),
                label: const Text(
                  'Remove',
                  style: TextStyle(color: ArkadColors.lightRed),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
