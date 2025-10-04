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
            helperStyle: TextStyle(color: ArkadColors.gray),
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
            helperStyle: TextStyle(color: ArkadColors.gray),
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
        // Programme dropdown with defensive null handling
        DropdownButtonFormField<Programme>(
          decoration: const InputDecoration(
            labelText: 'Programme',
            border: OutlineInputBorder(),
            helperText: 'Optional',
            helperStyle: TextStyle(color: ArkadColors.gray),
          ),
          initialValue: selectedProgramme != null && 
                        availableProgrammes.any((p) => p.value == selectedProgramme) 
                        ? selectedProgramme 
                        : null, // Reset to null if selected programme is not in list
          hint: const Text('Select your programme'),
          items: availableProgrammes.map((program) {
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
            helperStyle: TextStyle(color: ArkadColors.gray),
          ),
          initialValue: studyYear,
          hint: const Text('Select your study year'),
          items: [1, 2, 3, 4, 5].map((year) {
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
            helperStyle: TextStyle(color: ArkadColors.gray),
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
            helperStyle: TextStyle(color: ArkadColors.gray),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: foodPreferencesController,
          readOnly: readOnlyMode,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(
            labelText: 'Food Preferences',
            hintText: 'e.g., Vegetarian, allergic to nuts, etc.',
            border: OutlineInputBorder(),
            helperText:
                'Please specify your allergies, or leave blank if none.',
            helperStyle: TextStyle(color: ArkadColors.gray),
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
              backgroundImage: selectedProfileImage != null
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
                decoration: const BoxDecoration(
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
              style: TextStyle(color: ArkadColors.lightRed, fontSize: 14),
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
    final hasCV =
        selectedCV != null ||
        (!cvDeleted && currentCV != null && currentCV.isNotEmpty);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status container with green background and turquoise border
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hasCV
                ? ArkadColors.arkadGreen.withValues(alpha: 0.1)
                : ArkadColors.arkadLightNavy,
            border: Border.all(color: ArkadColors.arkadTurkos, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                hasCV ? Icons.check_circle : Icons.upload_file,
                color: hasCV ? ArkadColors.arkadGreen : ArkadColors.gray,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  selectedCV != null
                      ? 'Current: ${selectedCV.path.split('/').last}'
                      : (cvDeleted
                            ? 'No CV uploaded'
                            : (currentCV != null && currentCV.isNotEmpty
                                  ? 'Current: ${currentCV.split('/').last}'
                                  : 'No CV uploaded')),
                  style: const TextStyle(
                    color: ArkadColors.white,
                    fontSize: 14,
                    fontFamily: 'MyriadProCondensed',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Helper text
        const Text(
          'CV / Resume (Optional)',
          style: TextStyle(
            color: ArkadColors.gray,
            fontSize: 12,
            fontFamily: 'MyriadProCondensed',
          ),
        ),

        const SizedBox(height: 12),

        // Side-by-side buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPickCV,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArkadColors.arkadTurkos,
                  side: const BorderSide(
                    color: ArkadColors.arkadTurkos,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.attach_file, size: 18),
                label: Text(
                  hasCV ? 'Change CV' : 'Upload CV',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'MyriadProCondensed',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            if (hasCV && onDeleteCV != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: onDeleteCV,
                style: OutlinedButton.styleFrom(
                  foregroundColor: ArkadColors.lightRed,
                  side: const BorderSide(
                    color: ArkadColors.lightRed,
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete, size: 18),
                label: const Text(
                  'Remove',
                  style: TextStyle(
                    fontSize: 14,
                    fontFamily: 'MyriadProCondensed',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
