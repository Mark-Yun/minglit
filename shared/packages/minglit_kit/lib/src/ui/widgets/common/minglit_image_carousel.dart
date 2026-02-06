import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';

/// **Minglit Image Carousel**
///
/// A reusable carousel widget for displaying multiple images.
/// Used in Party/Event detail screens.
class MinglitImageCarousel extends StatefulWidget {
  const MinglitImageCarousel({
    required this.imageUrls,
    super.key,
    this.height = 300,
    this.fit = BoxFit.cover,
    this.onImageTap,
  });

  final List<String> imageUrls;
  final double height;
  final BoxFit fit;
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
    if (widget.imageUrls.isEmpty) {
      return Container(
        height: widget.height,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Icon(Icons.image_not_supported_outlined, size: 48),
      );
    }

    return Stack(
      children: [
        // 1. Carousel
        SizedBox(
          height: widget.height,
          child: PageView.builder(
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
          ),
        ),

        // 2. Indicator (Page count style)
        if (widget.imageUrls.length > 1)
          Positioned(
            bottom: MinglitSpacing.medium,
            right: MinglitSpacing.medium,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.small,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(MinglitRadius.card),
              ),
              child: Text(
                '${_currentIndex + 1} / ${widget.imageUrls.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
