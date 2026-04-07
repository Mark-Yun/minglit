import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all spacing tokens.
class SpacingSection extends StatelessWidget {
  /// Creates a [SpacingSection].
  const SpacingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const spacings = <String, double>{
      'zero': MinglitSpacing.zero,
      'xxsmall (2)': MinglitSpacing.xxsmall,
      'xsmall (4)': MinglitSpacing.xsmall,
      'xsmall2 (6)': MinglitSpacing.xsmall2,
      'small (8)': MinglitSpacing.small,
      'sm (12)': MinglitSpacing.sm,
      'medium (16)': MinglitSpacing.medium,
      'large (24)': MinglitSpacing.large,
      'xlarge (32)': MinglitSpacing.xlarge,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: spacings.length,
      itemBuilder: (context, index) {
        final entry = spacings.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Container(
                width: entry.value,
                height: 24,
                decoration: BoxDecoration(
                  color: MinglitColors.primary.withAlpha(180),
                  borderRadius: BorderRadius.circular(MinglitRadius.small),
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                '${entry.value.toInt()}px',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
