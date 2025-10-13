#!/usr/bin/env dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;

const String apiUrl = 'https://backend.arkadtlth.se/api/company/';
const String assetsDir = 'assets/images/companies';

/// Creates a circular version of an image
Future<bool> createCircularImage(String inputPath, String outputPath) async {
  try {
    // Read the original image
    final bytes = await File(inputPath).readAsBytes();
    var image = img.decodeImage(bytes);

    if (image == null) {
      print('  ⚠️  Failed to decode image for circular version');
      return false;
    }

    // Resize to 256px width while maintaining aspect ratio
    if (image.width > 256) {
      print('  📐 Resizing circular image to 256px width...');
      image = img.copyResize(
        image,
        width: 256,
        interpolation: img.Interpolation.linear,
      );
    }

    // Determine the size for the circular image (use the smaller dimension)
    final size = math.min(image.width, image.height);

    // Create a new square image with RGBA format for transparency
    final circularImage = img.Image(
      width: size,
      height: size,
      numChannels: 4, // RGBA
    );

    final radius = size / 2;
    final center = size / 2;

    // Calculate source offsets to center-crop the original image
    final srcOffsetX = (image.width - size) ~/ 2;
    final srcOffsetY = (image.height - size) ~/ 2;

    // Process each pixel
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        // Calculate distance from center
        final dx = x - center + 0.5;
        final dy = y - center + 0.5;
        final distance = math.sqrt(dx * dx + dy * dy);

        // Only copy pixels within the circle, leave rest transparent
        if (distance <= radius) {
          final srcX = x + srcOffsetX;
          final srcY = y + srcOffsetY;

          if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
            final pixel = image.getPixel(srcX, srcY);
            circularImage.setPixel(x, y, pixel);
          } else {
            // Outside source bounds but inside circle - set transparent
            circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        } else {
          // Outside circle - set transparent
          circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    // Encode and save the circular image as PNG (PNG supports transparency)
    final circularBytes = img.encodePng(circularImage);
    await File(outputPath).writeAsBytes(circularBytes);

    return true;
  } catch (e) {
    print('  ❌ Error creating circular image: $e');
    return false;
  }
}

Future<void> main() async {
  print('Starting company logo download...');
  print('API URL: $apiUrl');
  print('Target directory: $assetsDir');
  print('');

  try {
    // Fetch company data from API
    print('Fetching company data from API...');
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode != 200) {
      print(
        'Error: Failed to fetch companies. Status code: ${response.statusCode}',
      );
      exit(1);
    }

    final List<dynamic> companies = json.decode(response.body);
    print('Found ${companies.length} companies');
    print('');

    // Create assets directory if it doesn't exist
    final assetsDirectory = Directory(assetsDir);
    if (!await assetsDirectory.exists()) {
      await assetsDirectory.create(recursive: true);
      print('Created directory: $assetsDir');
    }

    int downloadedCount = 0;
    int circularCreatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    // Download each logo
    for (var i = 0; i < companies.length; i++) {
      final company = companies[i];
      final companyId = company['id'];
      final companyName = company['name'] ?? 'Unknown';
      final logoUrl = company['logoUrl'];

      print(
        '[${i + 1}/${companies.length}] Processing: $companyName (ID: $companyId)',
      );

      if (companyId == null) {
        print('  ⚠ Skipped: No company ID available');
        skippedCount++;
        continue;
      }

      if (logoUrl == null || logoUrl.isEmpty) {
        print('  ⚠ Skipped: No logo URL available');
        skippedCount++;
        continue;
      }

      try {
        // Build full URL if it's a relative path
        String fullLogoUrl = logoUrl;
        if (!logoUrl.startsWith('http')) {
          fullLogoUrl = logoUrl.startsWith('/')
              ? 'https://backend.arkadtlth.se$logoUrl'
              : 'https://backend.arkadtlth.se/$logoUrl';
        }

        print('  📥 Downloading from: $fullLogoUrl');

        // Download the logo
        final logoResponse = await http.get(Uri.parse(fullLogoUrl));

        if (logoResponse.statusCode != 200) {
          print(
            '  ❌ Error: Failed to download (status ${logoResponse.statusCode})',
          );
          errorCount++;
          continue;
        }

        // Determine file extension from URL or content-type
        String extension = path.extension(fullLogoUrl);
        if (extension.isEmpty || extension.contains('?')) {
          // Try to get extension from content-type
          final contentType = logoResponse.headers['content-type'] ?? '';
          if (contentType.contains('png')) {
            extension = '.png';
          } else if (contentType.contains('jpg') ||
              contentType.contains('jpeg')) {
            extension = '.jpg';
          } else if (contentType.contains('svg')) {
            extension = '.svg';
          } else if (contentType.contains('webp')) {
            extension = '.webp';
          } else {
            extension = '.png'; // default
          }
        }

        // Clean extension (remove query parameters)
        extension = extension.split('?').first;

        // Use company ID as filename
        final fileName = '$companyId$extension';
        final filePath = path.join(assetsDir, fileName);

        // Save the file
        final file = File(filePath);
        await file.writeAsBytes(logoResponse.bodyBytes);

        // Verify file was written successfully
        if (await file.exists()) {
          print(
            '  ✅ Saved: $fileName (${(logoResponse.bodyBytes.length / 1024).toStringAsFixed(1)} KB)',
          );
          downloadedCount++;

          // Create circular version
          print('  🔄 Creating circular version...');
          final circularFileName = '$companyId-circle.png';
          final circularFilePath = path.join(assetsDir, circularFileName);

          final circularSuccess =
              await createCircularImage(filePath, circularFilePath);

          if (circularSuccess) {
            final circularFile = File(circularFilePath);
            final circularSize = await circularFile.length();
            print(
              '  ✅ Created circular: $circularFileName (${(circularSize / 1024).toStringAsFixed(1)} KB)',
            );
            circularCreatedCount++;
          } else {
            print('  ⚠️  Failed to create circular version');
          }
        } else {
          print(
            '  ⚠️  WARNING: Logo URL exists but file was not saved: $fileName',
          );
          errorCount++;
        }
      } catch (e) {
        print('  ❌ Error: $e');
        errorCount++;
      }
      print('');
    }

    // Summary
    print('═══════════════════════════════════════');
    print('Download Summary:');
    print('  ✅ Successfully downloaded: $downloadedCount');
    print('  🔵 Circular versions created: $circularCreatedCount');
    print('  ⚠  Skipped (no logo): $skippedCount');
    print('  ❌ Errors: $errorCount');
    print('  📊 Total companies: ${companies.length}');
    print('═══════════════════════════════════════');
  } catch (e) {
    print('Fatal error: $e');
    exit(1);
  }
}
