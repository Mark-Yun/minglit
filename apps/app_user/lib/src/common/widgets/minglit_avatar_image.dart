import 'package:flutter/material.dart';

/// Circular avatar widget backed by a cached, resize-optimised network image.
///
/// Replaces direct `CircleAvatar(backgroundImage: NetworkImage(url))` usage,
/// which skips ResizeImage cache-width optimisation and has no error handling.
///
/// Shows [fallbackIcon] in a plain `CircleAvatar` when [url] is null, while
/// the image is loading, or when the image fails to load.
class MinglitAvatarImage extends StatelessWidget {
  const MinglitAvatarImage({
    required this.radius,
    this.url,
    this.fallbackIcon = Icons.person,
    this.backgroundColor,
    this.fallbackIconColor,
    super.key,
  });

  final double radius;
  final String? url;
  final IconData fallbackIcon;
  final Color? backgroundColor;
  final Color? fallbackIconColor;

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;

    final Widget placeholder = CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      child: Icon(fallbackIcon, color: fallbackIconColor, size: radius),
    );

    if (url == null || url!.isEmpty) return placeholder;

    // Fix #1936: decode at physical-pixel size to avoid full-res decode on scroll
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final cacheW = (size * dpr).round();

    return ClipOval(
      child: Image(
        image: ResizeImage.resizeIfNeeded(cacheW, cacheW, NetworkImage(url!)),
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return placeholder;
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      ),
    );
  }
}
