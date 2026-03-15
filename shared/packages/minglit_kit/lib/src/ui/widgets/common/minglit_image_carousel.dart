import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';

/// **Minglit Image Carousel**
///
/// A reusable carousel widget for displaying multiple images.
/// Used in Party/Event detail screens.
class MinglitImageCarousel extends StatefulWidget {
  /// Creates an image carousel for a list of URLs.
  ///
  /// When [height] is provided, the carousel uses a fixed height.
  /// When [height] is null, the carousel uses 16:9 aspect ratio
  /// based on the available width (responsive layout).
  const MinglitImageCarousel({
    required this.imageUrls,
    super.key,
    this.height,
    this.fit = BoxFit.cover,
    this.onImageTap,
  });

  /// Image URLs to display in the carousel.
  final List<String> imageUrls;

  /// Optional fixed height for the carousel viewport.
  /// When null, uses 16:9 aspect ratio based on available width.
  final double? height;

  /// BoxFit used for each image.
  final BoxFit fit;

  /// Callback invoked when an image is tapped.
  final void Function(int index)? onImageTap;

  @override
  State<MinglitImageCarousel> createState() => _MinglitImageCarouselState();
}

class _MinglitImageCarouselState extends State<MinglitImageCarousel> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final useFixedHeight = widget.height != null;

    // Fix #74: Show styled placeholder when no images available
    if (widget.imageUrls.isEmpty) {
      final theme = Theme.of(context);
      final placeholder = Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Icon(Icons.image, color: theme.colorScheme.outline),
      );
      return useFixedHeight
          ? SizedBox(height: widget.height, child: placeholder)
          : AspectRatio(aspectRatio: 16 / 9, child: placeholder);
    }

    Widget carousel = PageView.builder(
      controller: _pageController,
      itemCount: widget.imageUrls.length,
      onPageChanged: (index) => setState(() => _currentIndex = index),
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => widget.onImageTap?.call(index),
          child: MinglitImage(
            path: widget.imageUrls[index],
            fit: widget.fit,
            width: double.infinity,
            height: widget.height,
          ),
        );
      },
    );

    carousel = useFixedHeight
        ? SizedBox(height: widget.height, child: carousel)
        : AspectRatio(aspectRatio: 16 / 9, child: carousel);

    return Stack(
      children: [
        // 1. Carousel
        carousel,

        // 2. Indicator (Page count style)
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: MinglitSpacing.medium,
            right: MinglitSpacing.medium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.small,
                vertical: MinglitSpacing.xsmall,
              ),
              decoration: BoxDecoration(
                color: MinglitColors.textPrimary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: theme.textTheme.bodySmall!.copyWith(
                  color: MinglitColors.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
