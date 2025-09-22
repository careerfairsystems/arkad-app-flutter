import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'file_validation_service.dart';

/// Service for handling file operations (image picking, CV selection)
class FileService {
  final ImagePicker _imagePicker;

  FileService(this._imagePicker);

  /// Pick profile image from gallery with immediate validation
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
        final imageFile = File(image.path);
        
        // Immediate validation for better UX
        final validation = await FileValidationService.validateProfilePicture(imageFile);
        if (validation.isFailure) {
          _showErrorSnackbar(context, validation.errorOrNull!.userMessage);
          return null;
        }
        
        return imageFile;
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to pick image: $e');
      }
    }
    return null;
  }

  /// Pick CV file with immediate validation and support for multiple document types
  Future<File?> pickCVFile({
    required BuildContext context,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      // Use validation service constants for consistent allowed extensions
      final extensions = allowedExtensions ?? FileValidationService.allowedDocumentTypes;
      
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        dialogTitle: dialogTitle ?? 'Select CV (PDF, DOC, DOCX)',
        withData: true,
      );

      if (!context.mounted) return null;

      File? cvFile;
      
      if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.path != null) {
        cvFile = File(result.files.first.path!);
      } else if (result != null &&
          result.files.isNotEmpty &&
          result.files.first.bytes != null) {
        final tempDir = await getTemporaryDirectory();

        if (!context.mounted) return null;

        cvFile = File('${tempDir.path}/${result.files.first.name}');
        await cvFile.writeAsBytes(result.files.first.bytes!);
      }

      if (cvFile != null) {
        // Immediate validation for better UX
        final validation = await FileValidationService.validateCVFile(cvFile);
        if (validation.isFailure) {
          _showErrorSnackbar(context, validation.errorOrNull!.userMessage);
          return null;
        }
        
        return cvFile;
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
