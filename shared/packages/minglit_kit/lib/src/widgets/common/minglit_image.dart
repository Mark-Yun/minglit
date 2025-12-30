import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A smart image widget that shows a shimmer effect while loading.
class MinglitImage extends StatelessWidget {
  const MinglitImage({
    required this.assetPath,
    super.key,
    this.height,
    this.width,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final double? height;
  final double? width;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded || frame != null) {
          return child;
        }
        return Shimmer.fromColors(
          baseColor: Colors.grey[200]!,
          highlightColor: Colors.white,
          child: Container(
            height: height,
            width: width ?? (height != null ? height! * 2 : null),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          height: height,
          width: width,
          color: Colors.grey[100],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        );
      },
    );
  }
}
