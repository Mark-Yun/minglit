import 'package:flutter/material.dart';
import 'package:mds/src/theme/minglit_theme.dart';

/// Visualises event capacity — confirmed (filled) and pending (waiting) against total.
///
/// Automatically switches between:
/// - **segmented**: one slot per person (total ≤ [segmentThreshold], default 30)
/// - **continuous**: linear bar overlay (total > [segmentThreshold])
class MinglitCapacityBar extends StatelessWidget {
  const MinglitCapacityBar({
    required this.total,
    required this.filled,
    this.pending = 0,
    this.segmentThreshold = 30,
    this.height,
    this.segmentGap = 2,
    this.color,
    this.pendingColor,
    this.trackColor,
    this.radius,
    super.key,
  }) : assert(total >= 0),
       assert(filled >= 0),
       assert(pending >= 0);

  final int total;
  final int filled;
  final int pending;
  final int segmentThreshold;
  final double? height;
  final double segmentGap;
  final Color? color;
  final Color? pendingColor;
  final Color? trackColor;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = color ?? (isDark ? MinglitColorsDark.primary : MinglitColors.primary);
    final baseTrackColor = trackColor ?? (isDark ? MinglitColorsDark.divider : MinglitColors.divider);
    final basePendingColor = pendingColor ?? baseColor.withOpacity(0.3);

    if (total <= 0) return const SizedBox.shrink();

    if (total <= segmentThreshold) {
      return _SegmentedBar(
        total: total,
        filled: filled,
        pending: pending,
        height: height ?? 8,
        segmentGap: segmentGap,
        filledColor: baseColor,
        pendingColor: basePendingColor,
        trackColor: baseTrackColor,
        radius: radius ?? 2,
      );
    }

    return _ContinuousBar(
      total: total,
      filled: filled,
      pending: pending,
      height: height ?? 6,
      filledColor: baseColor,
      pendingColor: basePendingColor,
      trackColor: baseTrackColor,
      radius: radius ?? 3,
    );
  }
}

class _SegmentedBar extends StatelessWidget {
  const _SegmentedBar({
    required this.total,
    required this.filled,
    required this.pending,
    required this.height,
    required this.segmentGap,
    required this.filledColor,
    required this.pendingColor,
    required this.trackColor,
    required this.radius,
  });

  final int total;
  final int filled;
  final int pending;
  final double height;
  final double segmentGap;
  final Color filledColor;
  final Color pendingColor;
  final Color trackColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final safeFilled = filled.clamp(0, total);
    final safePending = pending.clamp(0, total - safeFilled);

    return Row(
      children: [
        for (int i = 0; i < total; i++) ...[
          if (i > 0) SizedBox(width: segmentGap),
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: i < safeFilled
                    ? filledColor
                    : i < safeFilled + safePending
                        ? pendingColor
                        : trackColor,
                borderRadius: BorderRadius.circular(radius),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ContinuousBar extends StatelessWidget {
  const _ContinuousBar({
    required this.total,
    required this.filled,
    required this.pending,
    required this.height,
    required this.filledColor,
    required this.pendingColor,
    required this.trackColor,
    required this.radius,
  });

  final int total;
  final int filled;
  final int pending;
  final double height;
  final Color filledColor;
  final Color pendingColor;
  final Color trackColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final safeFilled = filled.clamp(0, total);
    final safePending = pending.clamp(0, total - safeFilled);
    final filledFraction = safeFilled / total;
    final pendingFraction = safePending / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final filledWidth = totalWidth * filledFraction;
            final pendingWidth = totalWidth * pendingFraction;

            return Stack(
              children: [
                Container(width: totalWidth, color: trackColor),
                if (pendingFraction > 0)
                  Positioned(
                    left: filledWidth,
                    top: 0,
                    bottom: 0,
                    width: pendingWidth,
                    child: Container(color: pendingColor),
                  ),
                if (filledFraction > 0)
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: filledWidth,
                    child: Container(color: filledColor),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
