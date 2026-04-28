import 'package:flutter/material.dart';
import 'package:mds/src/ui/widgets/common/minglit_image.dart';

/// Circular avatar that delegates to [MinglitImage] for network images.
///
/// Shows a [CircleAvatar] fallback with [fallbackIcon] when [url] is null
/// or empty. Network images are loaded, cached, and clipped by [MinglitImage]
/// so all image policy (resize optimisation, shimmer, error handling) lives
/// in one place.
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

    if (url == null || url!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(fallbackIcon, color: fallbackIconColor, size: radius),
      );
    }

    return ClipOval(
      child: MinglitImage(
        path: url!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }
}
