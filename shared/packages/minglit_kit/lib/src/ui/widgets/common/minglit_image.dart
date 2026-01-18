import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:shimmer/shimmer.dart';

/// A smart image widget that shows a shimmer effect while loading.
/// Handles network URLs, assets, and local file paths (including Web blobs).
class MinglitImage extends StatelessWidget {
  const MinglitImage({
    required this.path,
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final String path;
  final double? height;
  final double? width;
  final BoxFit fit;

  bool get _isNetwork => path.startsWith('http');
  bool get _isAsset =>
      !path.startsWith('http') &&
      !path.startsWith('blob:') &&
      !path.contains('/');
  @override
  Widget build(BuildContext context) {
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
