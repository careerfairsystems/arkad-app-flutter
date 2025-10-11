import 'package:flutter/services.dart';

/// Utilities for working with Flutter assets
class AssetUtils {
  /// Checks if an asset exists in the asset bundle
  ///
  /// Returns true if the asset at [assetPath] exists, false otherwise.
  /// This is useful for conditionally loading assets without throwing errors.
  ///
  /// Example:
  /// ```dart
  /// if (await AssetUtils.assetExists('images/logo.png')) {
  ///   // Load the asset
  /// }
  /// ```
  static Future<bool> assetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }
}
