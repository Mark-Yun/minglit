import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// A public widget that displays participant count as a 3-segment gauge.
///
/// Renders a visual gauge with 3 segments that fill based on the ratio of
/// [current] to [max] participants. Segments are colored:
/// - 0-33%: Orange (secondary)
/// - 34-66%: Mint (tertiary)
/// - 67-100%: Purple (primary)
///
/// Designed for light surface backgrounds (e.g., card surfaces).
class MinglitParticipantGauge extends StatelessWidget {
  /// Creates a participant gauge widget.
  const MinglitParticipantGauge({
    required this.current,
    required this.max,
    super.key,
  });

  /// Current number of participants.
  final int current;

  /// Maximum capacity.
  final int max;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final filledCount = ratio <= 0
        ? 0
        : ratio <= 0.33
        ? 1
        : ratio <= 0.66
        ? 2
        : 3;
    final segmentColor = switch (filledCount) {
      0 => Theme.of(context).colorScheme.outlineVariant,
      1 => MinglitColors.secondary,
      2 => MinglitColors.tertiary,
      _ => MinglitColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.xsmall2,
        vertical: MinglitSpacing.xxsmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3-segment battery gauge
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 10,
              height: 8,
              decoration: BoxDecoration(
                color: i < filledCount
                    ? segmentColor
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Text(
            '$current/$max',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.people_outline,
            size: 11,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
