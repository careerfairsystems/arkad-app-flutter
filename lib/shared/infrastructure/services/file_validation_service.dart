import 'dart:io';
import 'dart:typed_data';

import '../../domain/result.dart';
import '../../errors/app_error.dart';

/// Service for validating file uploads according to security guidelines
/// Implements proactive validation to prevent unnecessary server requests
class FileValidationService {
  // File size limits from CLAUDE.md security guidelines
  static const maxCVSize = 10 * 1024 * 1024; // 10MB
  static const maxProfilePictureSize = 5 * 1024 * 1024; // 5MB

  // Allowed file types from CLAUDE.md security guidelines
  static const allowedDocumentTypes = ['pdf', 'doc', 'docx'];
  static const allowedImageTypes = ['jpg', 'jpeg', 'png', 'webp'];

  /// Validate CV file for size and type
  static Future<Result<void>> validateCVFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return Result.failure(
          const ValidationError(
            'Selected file no longer exists. Please select again.',
          ),
        );
      }

      // Check file extension
      final extension = _getFileExtension(file.path);
      if (!allowedDocumentTypes.contains(extension)) {
        return Result.failure(
          ValidationError(
            'Invalid file type. CV must be: ${allowedDocumentTypes.join(', ').toUpperCase()}',
          ),
        );
      }

      // Check file size
      final fileSize = await _getFileSize(file);
      if (fileSize > maxCVSize) {
        final maxSizeMB = (maxCVSize / (1024 * 1024)).toInt();
        return Result.failure(
          ValidationError(
            'CV file is too large. Maximum size is ${maxSizeMB}MB.',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(const ValidationError('Unable to validate file'));
    }
  }

  /// Validate profile picture file for size and type
  static Future<Result<void>> validateProfilePicture(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return Result.failure(
          const ValidationError(
            'Selected image no longer exists. Please select again.',
          ),
        );
      }

      // Check file extension
      final extension = _getFileExtension(file.path);
      if (!allowedImageTypes.contains(extension)) {
        return Result.failure(
          ValidationError(
            'Invalid image type. Profile picture must be: ${allowedImageTypes.join(', ').toUpperCase()}',
          ),
        );
      }

      // Check file size
      final fileSize = await _getFileSize(file);
      if (fileSize > maxProfilePictureSize) {
        final maxSizeMB = (maxProfilePictureSize / (1024 * 1024)).toInt();
        return Result.failure(
          ValidationError(
            'Image file is too large. Maximum size is ${maxSizeMB}MB.',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        const ValidationError('Unable to validate profile picture'),
      );
    }
  }

  /// Get file extension from file path (lowercase)
  static String _getFileExtension(String filePath) {
    final parts = filePath.split('.');
    if (parts.length < 2) return '';
    return parts.last.toLowerCase();
  }

  /// Get file size in bytes
  static Future<int> _getFileSize(File file) async {
    try {
      return await file.length();
    } catch (e) {
      throw Exception('Could not determine file size');
    }
  }

  /// Get human-readable file size string
  static String getFileSizeString(int bytes) {
    const int kb = 1024;
    const int mb = kb * 1024;

    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(1)} MB';
    } else if (bytes >= kb) {
      return '${(bytes / kb).toStringAsFixed(1)} KB';
    } else {
      return '$bytes bytes';
    }
  }

  /// Check if file type is a supported document
  static bool isDocumentType(String filePath) {
    final extension = _getFileExtension(filePath);
    return allowedDocumentTypes.contains(extension);
  }

  /// Check if file type is a supported image
  static bool isImageType(String filePath) {
    final extension = _getFileExtension(filePath);
    return allowedImageTypes.contains(extension);
  }

  /// Validate CV file using bytes and filename (web-compatible)
  static Result<void> validateCVFromBytes(Uint8List bytes, String filename) {
    try {
      // Check file extension
      final extension = _getFileExtension(filename);
      if (!allowedDocumentTypes.contains(extension)) {
        return Result.failure(
          ValidationError(
            'Invalid file type. CV must be: ${allowedDocumentTypes.join(', ').toUpperCase()}',
          ),
        );
      }

      // Check file size
      if (bytes.length > maxCVSize) {
        final maxSizeMB = (maxCVSize / (1024 * 1024)).toInt();
        return Result.failure(
          ValidationError(
            'CV file is too large. Maximum size is ${maxSizeMB}MB.',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(const ValidationError('Unable to validate file'));
    }
  }

  /// Validate profile picture using bytes and filename (web-compatible)
  static Result<void> validateProfilePictureFromBytes(
    Uint8List bytes,
    String filename,
  ) {
    try {
      // Check file extension
      final extension = _getFileExtension(filename);
      if (!allowedImageTypes.contains(extension)) {
        return Result.failure(
          ValidationError(
            'Invalid image type. Profile picture must be: ${allowedImageTypes.join(', ').toUpperCase()}',
          ),
        );
      }

      // Check file size
      if (bytes.length > maxProfilePictureSize) {
        final maxSizeMB = (maxProfilePictureSize / (1024 * 1024)).toInt();
        return Result.failure(
          ValidationError(
            'Image file is too large. Maximum size is ${maxSizeMB}MB.',
          ),
        );
      }

      return Result.success(null);
    } catch (e) {
      return Result.failure(
        const ValidationError('Unable to validate profile picture'),
      );
    }
  }
}
