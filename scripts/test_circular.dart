#!/usr/bin/env dart

import 'dart:io';
import 'dart:math' as math;
import 'package:image/image.dart' as img;

Future<bool> createCircularImage(String inputPath, String outputPath) async {
  try {
    final bytes = await File(inputPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      print('Failed to decode image');
      return false;
    }

    final size = math.min(image.width, image.height);
    final circularImage = img.Image(width: size, height: size, numChannels: 4);
    final radius = size / 2;
    final center = size / 2;
    final srcOffsetX = (image.width - size) ~/ 2;
    final srcOffsetY = (image.height - size) ~/ 2;

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final dx = x - center + 0.5;
        final dy = y - center + 0.5;
        final distance = math.sqrt(dx * dx + dy * dy);

        if (distance <= radius) {
          final srcX = x + srcOffsetX;
          final srcY = y + srcOffsetY;
          if (srcX >= 0 && srcX < image.width && srcY >= 0 && srcY < image.height) {
            final pixel = image.getPixel(srcX, srcY);
            circularImage.setPixel(x, y, pixel);
          } else {
            circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
          }
        } else {
          circularImage.setPixelRgba(x, y, 0, 0, 0, 0);
        }
      }
    }

    final circularBytes = img.encodePng(circularImage);
    await File(outputPath).writeAsBytes(circularBytes);
    return true;
  } catch (e) {
    print('Error: $e');
    return false;
  }
}

Future<void> main() async {
  print('Testing circular image with transparency...');
  final success = await createCircularImage(
    'assets/images/companies/163.png',
    'assets/images/companies/163-circle-test.png',
  );

  if (success) {
    print('✅ Created test circular image: 163-circle-test.png');
    print('Please check if the background is transparent');
  } else {
    print('❌ Failed to create circular image');
  }
}
