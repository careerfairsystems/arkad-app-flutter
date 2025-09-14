import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// An optimized image widget that provides caching, loading states, and error handling
///
/// Features:
/// - Memory and disk caching for improved performance
/// - Shimmer loading placeholder for better UX
/// - Graceful error handling with fallback widgets
/// - Optimized memory usage with size-based caching
/// - Smooth fade-in animations
class OptimizedImage extends StatelessWidget {
  const OptimizedImage({
    super.key,
    this.imageUrl,
    required this.width,
    required this.height,
    required this.fallbackWidget,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fadeInDuration = const Duration(milliseconds: 300),
    this.placeholderColor,
    this.highlightColor,
  });

  /// The URL of the image to load
  final String? imageUrl;

  /// The width of the image widget
  final double width;

  /// The height of the image widget
  final double height;

  /// Widget to show when image fails to load or URL is null/empty
  final Widget fallbackWidget;

  /// How the image should fit within its bounds
  final BoxFit fit;

  /// Border radius to apply to the image and placeholder
  final BorderRadius? borderRadius;

  /// Duration of the fade-in animation when image loads
  final Duration fadeInDuration;

  /// Base color for the shimmer placeholder
  final Color? placeholderColor;

  /// Highlight color for the shimmer placeholder
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    // Return fallback widget if URL is null or empty
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildContainer(fallbackWidget);
    }

    return _buildContainer(
      CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildShimmerPlaceholder(context),
        errorWidget: (context, url, error) => fallbackWidget,
        fadeInDuration: fadeInDuration,
        fadeOutDuration: const Duration(milliseconds: 200),
        // Optimize memory usage by caching at the display size
        memCacheWidth: _getCacheSize(width, context),
        memCacheHeight: _getCacheSize(height, context),
        // Better error handling
        errorListener: (error) {
          // Log error in debug mode for better debugging
          assert(() {
            debugPrint(
              'OptimizedImage failed to load: $imageUrl, Error: $error',
            );
            return true;
          }());
        },
      ),
    );
  }

  /// Wraps the content in a container with optional border radius
  Widget _buildContainer(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: width, height: height, child: child),
      );
    }

    return SizedBox(width: width, height: height, child: child);
  }

  /// Builds a shimmer loading placeholder
  Widget _buildShimmerPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor:
          placeholderColor ??
          theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
      highlightColor:
          highlightColor ?? theme.colorScheme.surface.withValues(alpha: 0.1),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  /// Calculates optimal cache size based on device pixel ratio
  int _getCacheSize(double size, BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    return (size * pixelRatio).round();
  }
}

/// A specialized optimized image for company logos
class CompanyLogoImage extends OptimizedImage {
  CompanyLogoImage({
    super.key,
    required String? logoUrl,
    required double size,
    Widget? fallbackWidget,
    BorderRadius? borderRadius,
  }) : super(
         imageUrl: logoUrl,
         width: size,
         height: size,
         fit: BoxFit.contain,
         borderRadius: borderRadius ?? BorderRadius.circular(12),
         fallbackWidget: fallbackWidget ?? _buildDefaultLogo(size),
       );

  /// Creates a default logo widget for company logos
  static Widget _buildDefaultLogo(double size) {
    return Builder(
      builder: (context) {
        final theme = Theme.of(context);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.1),
                theme.colorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
          child: Icon(
            Icons.business_rounded,
            size: size * 0.4,
            color: theme.colorScheme.primary.withValues(alpha: 0.7),
          ),
        );
      },
    );
  }
}
