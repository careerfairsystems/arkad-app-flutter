import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'file_validation_service.dart';

/// Platform-aware file representation that works on both web and mobile
class PlatformFile {
  const PlatformFile({required this.name, required this.bytes, this.path});

  final String name;
  final Uint8List bytes;
  final String? path; // null on web, actual path on mobile

  /// Check if this file has a local path (mobile only)
  bool get hasLocalPath => path != null;

  /// Get File object for mobile platforms only
  /// Throws StateError if called on web platform - use bytes instead
  File asFile() {
    if (path != null) {
      return File(path!);
    }
    throw StateError(
      'File path not available on web platform. Use bytes property instead.',
    );
  }

  /// Get file size in bytes
  int get size => bytes.length;
}

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
        final validation = await FileValidationService.validateProfilePicture(
          imageFile,
        );
        if (validation.isFailure) {
          if (context.mounted) {
            _showErrorSnackbar(context, validation.errorOrNull!.userMessage);
          }
          return null;
        }

        return imageFile;
      }
    } catch (e) {
      await Sentry.captureException(e);
      if (context.mounted) {
        _showErrorSnackbar(context, 'Failed to pick image: $e');
      }
    }
    return null;
  }

  /// Pick CV file with immediate validation and support for multiple document types
  /// Returns platform-aware file representation that works on both web and mobile
  Future<PlatformFile?> pickCVFile({
    required BuildContext context,
    List<String>? allowedExtensions,
    String? dialogTitle,
  }) async {
    try {
      // Use validation service constants for consistent allowed extensions
      final extensions =
          allowedExtensions ?? FileValidationService.allowedDocumentTypes;

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
        dialogTitle: dialogTitle ?? 'Select CV (PDF, DOC, DOCX)',
        withData: true, // Always request bytes for cross-platform compatibility
      );

      if (!context.mounted) return null;

      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;

        // Ensure we have bytes (required for both platforms)
        if (pickedFile.bytes == null) {
          if (context.mounted) {
            _showErrorSnackbar(context, 'Failed to read file data');
          }
          return null;
        }

        // Create platform-aware file representation
        final platformFile = PlatformFile(
          name: pickedFile.name,
          bytes: pickedFile.bytes!,
          path: kIsWeb
              ? null
              : pickedFile.path, // Path only available on mobile
        );

        // Immediate validation for better UX using platform-appropriate method
        if (kIsWeb) {
          // On web, validate directly from bytes without temporary files
          final validation = FileValidationService.validateCVFromBytes(
            pickedFile.bytes!,
            pickedFile.name,
          );

          if (validation.isFailure) {
            if (context.mounted) {
              _showErrorSnackbar(context, validation.errorOrNull!.userMessage);
            }
            return null;
          }
        } else {
          // On mobile, use traditional file validation
          final fileForValidation = File(pickedFile.path!);
          final validation = await FileValidationService.validateCVFile(
            fileForValidation,
          );

          if (validation.isFailure) {
            if (context.mounted) {
              _showErrorSnackbar(context, validation.errorOrNull!.userMessage);
            }
            return null;
          }
        }

        return platformFile;
      }

      if (context.mounted) {
        _showErrorSnackbar(
          context,
          'Could not select CV file. Please try again.',
        );
      }
    } catch (e) {
      await Sentry.captureException(e);
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
