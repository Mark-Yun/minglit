import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class SettlementListShimmer extends StatefulWidget {
  const SettlementListShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  State<SettlementListShimmer> createState() => _SettlementListShimmerState();
}

class _SettlementListShimmerState extends State<SettlementListShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    unawaited(_controller.repeat());
    _animation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: widget.itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (_, index) => const Divider(height: 1),
      itemBuilder: (_, index) => _ShimmerItem(animation: _animation),
    );
  }
}

class _ShimmerItem extends StatelessWidget {
  const _ShimmerItem({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final baseColor = onSurface.withValues(alpha: 0.12);
    final highlightColor = onSurface.withValues(alpha: 0.04);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerBox(
                      width: 200,
                      height: 14,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      value: animation.value,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    _ShimmerBox(
                      width: 120,
                      height: 11,
                      baseColor: baseColor,
                      highlightColor: highlightColor,
                      value: animation.value,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              _ShimmerBox(
                width: 56,
                height: 22,
                baseColor: baseColor,
                highlightColor: highlightColor,
                value: animation.value,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.baseColor,
    required this.highlightColor,
    required this.value,
  });

  final double width;
  final double height;
  final Color baseColor;
  final Color highlightColor;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // Fix #1195: BorderRadius 하드코딩 → MinglitRadius.badge 토큰
        borderRadius: BorderRadius.circular(MinglitRadius.badge),
        gradient: LinearGradient(
          colors: [baseColor, highlightColor, baseColor],
          stops: [
            (value - 0.5).clamp(0, 1),
            value.clamp(0, 1),
            (value + 0.5).clamp(0, 1),
          ],
        ),
      ),
    );
  }
}
