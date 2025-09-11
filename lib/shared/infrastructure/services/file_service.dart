import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service for handling file operations (image picking, CV selection)
class FileService {
  final ImagePicker _imagePicker;

  FileService(this._imagePicker);

  /// Pick profile image from gallery
  Future<File?> pickProfileImage({required BuildContext context}) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (!context.mounted) return null;

      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to pick image: $e');
      }
    }
    return null;
  }

  /// Pick CV file (PDF by default)
  Future<File?> pickCVFile({
    required BuildContext context,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions ?? ['pdf'],
        dialogTitle: dialogTitle,
        withData: true,
      );

      if (!context.mounted) return null;

      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        return File(result.files.first.path!);
      } else if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.bytes != null) {
        final tempDir = await getTemporaryDirectory();

        if (!context.mounted) return null;

        final file = File('${tempDir.path}/${result.files.first.name}');
        await file.writeAsBytes(result.files.first.bytes!);
        return file;
      }

      if (context.mounted) {
        _showErrorSnackbar(
          context,
          'Could not select CV file. Please try again.',
        );
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to pick CV: $e');
      }
    }
    return null;
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
