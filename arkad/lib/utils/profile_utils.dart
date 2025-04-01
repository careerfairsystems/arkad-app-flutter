import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/profile_completion_dialog.dart';
import '../models/user.dart';

class ProfileUtils {
  static Future<File?> pickProfileImage({
    required BuildContext context,
    required ImagePicker imagePicker,
  }) async {
    try {
      final XFile? image = await imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to pick image: $e');
    }
    return null;
  }

  static Future<File?> pickCVFile({
    required BuildContext context,
  }) async {
    try {
      // First attempt with file_picker
      try {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'doc', 'docx'],
          withData: true, // Load file bytes in memory
        );

        if (result != null &&
            result.files.isNotEmpty &&
            result.files.first.path != null) {
          return File(result.files.first.path!);
        } else if (result != null &&
            result.files.isNotEmpty &&
            result.files.first.bytes != null) {
          // If we have bytes but no path (e.g. on web), save to temporary file
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/${result.files.first.name}');
          await file.writeAsBytes(result.files.first.bytes!);
          return file;
        }
      } catch (e) {
        // If file_picker fails, we'll fall through to the next approach
        print('File picker error: $e');
      }

      // Alert user that file selection wasn't successful
      if (context.mounted) {
        _showErrorSnackbar(
            context, 'Could not select CV file. Please try again.');
      }
    } catch (e) {
      _showErrorSnackbar(context, 'Failed to pick CV: $e');
    }
    return null;
  }

  static void _showErrorSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  static Map<String, dynamic> prepareProfileData({
    required String firstName,
    required String lastName,
    required Programme? selectedProgramme,
    required String programmeText, // For fallback
    required String linkedin,
    required String masterTitle,
    required int? studyYear,
    required String foodPreferences,
  }) {
    final profileData = {
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      // Get the label from the selected programme enum
      'programme': selectedProgramme != null
          ? PROGRAMS.firstWhere(
              (prog) => prog['value'] == selectedProgramme)['label'] as String
          : programmeText.trim(),
      'linkedin': linkedin.trim(),
      'master_title': masterTitle.trim(),
      'study_year': studyYear,
      'food_preferences': foodPreferences.trim(),
    };

    // Remove null values to avoid overwriting with null
    profileData.removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));

    return profileData;
  }

  // Helper method to convert string programme to enum
  static Programme? programmeStringToEnum(String? programmeString) {
    if (programmeString == null || programmeString.isEmpty) {
      return null;
    }

    try {
      return PROGRAMS.firstWhere(
        (prog) => prog['label'] == programmeString,
        orElse: () => PROGRAMS[0],
      )['value'] as Programme;
    } catch (e) {
      return null;
    }
  }
}
