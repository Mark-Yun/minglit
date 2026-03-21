import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

// Private layout constants for the gauge widget.
const double _kPillRadius = 100;
const double _kSegmentRadius = 2;
const double _kSegmentWidth = 10;
const double _kGaugeTextSize = 11;
const double _kLowThreshold = 0.33;
const double _kMedThreshold = 0.66;
const int _kSegmentCount = 3;

/// A public widget that displays participant count as a 3-segment gauge.
///
/// Renders a visual gauge with 3 segments that fill based on the ratio of
/// [MinglitParticipantGauge.current] to [MinglitParticipantGauge.max]
/// Segments are colored:
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
        : ratio <= _kLowThreshold
            ? 1
            : ratio <= _kMedThreshold
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
        borderRadius: BorderRadius.circular(_kPillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3-segment battery gauge
          for (var i = 0; i < _kSegmentCount; i++) ...[
            if (i > 0) const SizedBox(width: MinglitSpacing.xxsmall),
            Container(
              width: _kSegmentWidth,
              height: MinglitSpacing.small,
              decoration: BoxDecoration(
                color: i < filledCount
                    ? segmentColor
                    : Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(_kSegmentRadius),
              ),
            ),
          ],
          const SizedBox(width: MinglitSpacing.xsmall2),
          Text(
            '$current/$max',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: _kGaugeTextSize,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(width: MinglitSpacing.xxsmall),
          Icon(
            Icons.people_outline,
            size: _kGaugeTextSize,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ],
      ),
    );
  }
}
