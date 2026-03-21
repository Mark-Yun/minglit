import 'dart:async' show unawaited;

import 'package:flutter/material.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
    final highlightColor =
        isDark ? const Color(0xFF4A4A4A) : const Color(0xFFF5F5F5);

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                    const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
        borderRadius: BorderRadius.circular(4),
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
