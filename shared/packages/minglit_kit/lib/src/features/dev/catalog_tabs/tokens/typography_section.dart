import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';

/// Design catalog tab displaying all typography styles.
class TypographySection extends StatelessWidget {
  /// Creates a [TypographySection].
  const TypographySection({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final styles = <String, TextStyle?>{
      'displayLarge': textTheme.displayLarge,
      'displayMedium': textTheme.displayMedium,
      'displaySmall': textTheme.displaySmall,
      'headlineLarge': textTheme.headlineLarge,
      'headlineMedium': textTheme.headlineMedium,
      'headlineSmall': textTheme.headlineSmall,
      'titleLarge': textTheme.titleLarge,
      'titleMedium': textTheme.titleMedium,
      'titleSmall': textTheme.titleSmall,
      'bodyLarge': textTheme.bodyLarge,
      'bodyMedium': textTheme.bodyMedium,
      'bodySmall': textTheme.bodySmall,
      'labelLarge': textTheme.labelLarge,
      'labelMedium': textTheme.labelMedium,
      'labelSmall': textTheme.labelSmall,
    };

    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      itemCount: styles.length,
      separatorBuilder: (context, index) => const Divider(),
      itemBuilder: (context, index) {
        final entry = styles.entries.elementAt(index);
        final style = entry.value;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.key, style: style ?? const TextStyle()),
              const SizedBox(height: MinglitSpacing.xsmall),
              Text(
                'size: ${style?.fontSize ?? "inherit"} '
                '/ weight: ${style?.fontWeight ?? "inherit"}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
