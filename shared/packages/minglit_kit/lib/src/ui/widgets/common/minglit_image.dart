import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:shimmer/shimmer.dart';

/// A smart image widget that shows a shimmer effect while loading.
/// Handles network URLs, assets, and local file paths (including Web blobs).
class MinglitImage extends StatelessWidget {
  /// Creates an image widget that supports network, assets, and local paths.
  const MinglitImage({
    required this.path,
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
    this.semanticLabel,
    this.excludeFromSemantics = false,
  });

  /// Image source path or URL.
  final String path;

  /// Optional fixed height for the image.
  final double? height;

  /// Optional fixed width for the image.
  final double? width;

  /// How the image should be inscribed into the space.
  final BoxFit fit;

  /// Semantic label for the image.
  final String? semanticLabel;

  /// Whether to exclude this image from semantics.
  final bool excludeFromSemantics;

  bool get _isNetwork => path.startsWith('http');
  bool get _isAsset =>
      !path.startsWith('http') &&
      !path.startsWith('blob:') &&
      !path.contains('/');
  @override
  Widget build(BuildContext context) {
    // Fix #1379: 빈 경로일 때 컴팩트 아이콘 플레이스홀더 표시 — MinglitEmptyState.card는
    // 32px 패딩+아이콘+텍스트로 60×80px 썸네일에서 overflow가 발생하므로 사용 불가
    if (path.trim().isEmpty) {
      final theme = Theme.of(context);
      return Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    ImageProvider provider;

    if (_isNetwork) {
      provider = NetworkImage(path);
    } else if (kIsWeb && path.startsWith('blob:')) {
      // Web blobs are handled like network images in Flutter Web
      provider = NetworkImage(path);
    } else if (_isAsset) {
      provider = AssetImage(path);
    } else {
      // Assuming it's a file path for native or other types of paths
      provider = AssetImage(path);
    }
    return Image(
      image: provider,
      height: height,
      width: width,
      fit: fit,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        final theme = Theme.of(context);
        return Shimmer.fromColors(
          baseColor: theme.colorScheme.surfaceContainer,
          highlightColor: theme.colorScheme.surface,
          child: Container(
            height: height,
            width: width ?? (height != null ? height! * 2 : null),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        final theme = Theme.of(context);
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(MinglitRadius.small),
          ),
          child: Icon(Icons.broken_image, color: theme.colorScheme.outline),
        );
      },
    );
  }
}
