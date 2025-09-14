import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Optimized image widget with caching, loading states, and error handling
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

  final String? imageUrl;
  final double width;
  final double height;
  final Widget fallbackWidget;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Duration fadeInDuration;
  final Color? placeholderColor;
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
        memCacheWidth: _getCacheSize(width, context),
        memCacheHeight: _getCacheSize(height, context),
        errorListener: (error) {
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

  Widget _buildContainer(Widget child) {
    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(width: width, height: height, child: child),
      );
    }

    return SizedBox(width: width, height: height, child: child);
  }

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
