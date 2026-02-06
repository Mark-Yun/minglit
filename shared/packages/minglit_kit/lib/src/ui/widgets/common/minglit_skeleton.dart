import 'dart:async';

import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A reusable skeleton loader with a subtle pulsing animation.
class MinglitSkeleton extends StatefulWidget {
  /// Creates a pulsing skeleton block.
  const MinglitSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  /// Optional fixed width of the skeleton.
  final double? width;

  /// Optional fixed height of the skeleton.
  final double? height;

  /// Optional custom border radius.
  final BorderRadiusGeometry? borderRadius;

  @override
  State<MinglitSkeleton> createState() => _MinglitSkeletonState();
}

class _MinglitSkeletonState extends State<MinglitSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MinglitAnimation.slow * 2,
    );
    unawaited(_controller.repeat(reverse: true));

    _colorAnimation = ColorTween(
      begin: const Color(0xFFF3F4F6), // Gray-100
      end: const Color(0xFFE5E7EB), // Gray-200
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
        );
      },
    );
  }
}
