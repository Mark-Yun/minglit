import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';
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
    // Fix #1558: 빈 경로 플레이스홀더에도 semantics 정책 적용
    if (path.trim().isEmpty) {
      final theme = Theme.of(context);
      final placeholder = Container(
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
      if (excludeFromSemantics) {
        return ExcludeSemantics(child: placeholder);
      }
      if (semanticLabel != null) {
        return Semantics(label: semanticLabel, child: placeholder);
      }
      return placeholder;
    }

    ImageProvider provider;

    // Derive pixel-aligned cache dimensions from logical size × DPR to avoid
    // decoding full-resolution images for small thumbnails during scroll.
    // Only applied when a finite, positive logical dimension is provided.
    // Guard against double.infinity (e.g. callers that pass width: double.infinity
    // for fill-parent semantics) — infinity × DPR cannot be converted to int.
    // perf: cacheWidth/cacheHeight reduce memory and decode cost on scroll.
    // Directive: cacheW must always be paired with a finite explicit width param.
    final double dpr = MediaQuery.devicePixelRatioOf(context);
    final int? cacheW = (width != null && width!.isFinite && width! > 0)
        ? (width! * dpr).round()
        : null;
    final int? cacheH = (height != null && height!.isFinite && height! > 0)
        ? (height! * dpr).round()
        : null;

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

    // Wrap with ResizeImage so the engine decodes at physical-pixel size
    // rather than full resolution. The base Image() constructor does not
    // expose cacheWidth/cacheHeight directly; ResizeImage is the public API.
    // perf: Directive: cacheW must always be paired with the explicit width
    // param on MinglitImage so the logical layout size is preserved.
    final ImageProvider resolvedProvider =
        ResizeImage.resizeIfNeeded(cacheW, cacheH, provider);

    return Image(
      image: resolvedProvider,
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
      // Fix #1558: errorBuilder에도 semantics 정책 적용
      // Fix #1655: 로드 실패 시 broken_image 대신 placeholder — 네트워크 오류/404 엑박 방지
      errorBuilder: (context, error, stackTrace) {
        final theme = Theme.of(context);
        final fallback = Container(
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
        if (excludeFromSemantics) return ExcludeSemantics(child: fallback);
        if (semanticLabel != null) {
          return Semantics(label: semanticLabel, child: fallback);
        }
        return fallback;
      },
    );
  }
}
