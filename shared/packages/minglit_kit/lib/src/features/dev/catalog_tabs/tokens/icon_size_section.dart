import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all icon size tokens.
class IconSizeSection extends StatelessWidget {
  /// Creates an [IconSizeSection].
  const IconSizeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const sizes = <String, double>{
      'xsmall (16)': MinglitIconSize.xsmall,
      'small (20)': MinglitIconSize.small,
      'medium (24)': MinglitIconSize.medium,
      'large (28)': MinglitIconSize.large,
      'xlarge (32)': MinglitIconSize.xlarge,
    };

    return ListView.builder(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: sizes.length,
      itemBuilder: (context, index) {
        final entry = sizes.entries.elementAt(index);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Row(
            children: [
              SizedBox(
                width: 120,
                child: Text(entry.key, style: theme.textTheme.bodyMedium),
              ),
              Icon(Icons.star, size: entry.value),
              const SizedBox(width: MinglitSpacing.small),
              Icon(Icons.favorite, size: entry.value),
              const SizedBox(width: MinglitSpacing.small),
              Icon(Icons.notifications, size: entry.value),
              const SizedBox(width: MinglitSpacing.medium),
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
