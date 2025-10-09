#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

const String apiUrl = 'https://backend.arkadtlth.se/api/company/';
const String assetsDir = 'assets/images/companies';

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
      print('Error: Failed to fetch companies. Status code: ${response.statusCode}');
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
    int skippedCount = 0;
    int errorCount = 0;

    // Download each logo
    for (var i = 0; i < companies.length; i++) {
      final company = companies[i];
      final companyId = company['id'];
      final companyName = company['name'] ?? 'Unknown';
      final logoUrl = company['logoUrl'];

      print('[${ i + 1}/${companies.length}] Processing: $companyName (ID: $companyId)');

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
          print('  ❌ Error: Failed to download (status ${logoResponse.statusCode})');
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
          } else if (contentType.contains('jpg') || contentType.contains('jpeg')) {
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
          print('  ✅ Saved: $fileName (${(logoResponse.bodyBytes.length / 1024).toStringAsFixed(1)} KB)');
          downloadedCount++;
        } else {
          print('  ⚠️  WARNING: Logo URL exists but file was not saved: $fileName');
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
    print('  ⚠  Skipped (no logo): $skippedCount');
    print('  ❌ Errors: $errorCount');
    print('  📊 Total companies: ${companies.length}');
    print('═══════════════════════════════════════');

  } catch (e) {
    print('Fatal error: $e');
    exit(1);
  }
}
