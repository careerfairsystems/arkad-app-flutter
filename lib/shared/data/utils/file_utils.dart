import 'dart:io';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';

/// Utility functions for file handling in data layer
class FileUtils {
  /// Convert a File to MultipartFile for API requests
  static Future<MultipartFile> getMultipartFile(File file) async {
    // Determine mime type
    final mimeType = lookupMimeType(file.path)!;
    final fileType = mimeType.split('/');

    // Add the file
    final fileBytes = await file.readAsBytes();

    return MultipartFile.fromBytes(
      fileBytes,
      filename: file.path.split('/').last,
      contentType: MediaType(fileType[0], fileType[1]),
    );
  }
}
