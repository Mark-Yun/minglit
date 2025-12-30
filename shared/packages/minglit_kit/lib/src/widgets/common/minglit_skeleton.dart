import 'dart:async';

import 'package:flutter/material.dart';

/// A reusable skeleton loader with a subtle pulsing animation.
class MinglitSkeleton extends StatefulWidget {
  const MinglitSkeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  final double? width;
  final double? height;
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
      duration: const Duration(milliseconds: 1000),
    );
    unawaited(_controller.repeat(reverse: true));

    _colorAnimation = ColorTween(
      begin: const Color(0xFFF3F4F6), // Gray-100
      end: const Color(0xFFE5E7EB),   // Gray-200
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
