import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/loading_indicator.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

/// Design catalog tab displaying loading indicator widgets.
class LoadingSection extends StatelessWidget {
  /// Creates a [LoadingSection].
  const LoadingSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // MinglitSkeleton
        Text('MinglitSkeleton', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitSkeleton(width: 200, height: 20),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitSkeleton(width: 150, height: 20),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: 100,
          height: 100,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text(
          'Card skeleton',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          width: double.infinity,
          height: 120,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitCircularProgressIndicator
        Text(
          'MinglitCircularProgressIndicator',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        const Row(
          children: [
            MinglitCircularProgressIndicator(),
            SizedBox(width: MinglitSpacing.large),
            MinglitCircularProgressIndicator(
              size: 32,
              strokeWidth: 3,
            ),
            SizedBox(width: MinglitSpacing.large),
            MinglitCircularProgressIndicator(
              size: 48,
              strokeWidth: 4,
              color: MinglitColors.success,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitLinearProgressIndicator
        Text(
          'MinglitLinearProgressIndicator',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: MinglitSpacing.small),
        Text('Indeterminate', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(),
        const SizedBox(height: MinglitSpacing.medium),
        Text('30%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(value: 0.3),
        const SizedBox(height: MinglitSpacing.medium),
        Text('70%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(value: 0.7),
        const SizedBox(height: MinglitSpacing.medium),
        Text('100%', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitLinearProgressIndicator(
          value: 1,
          color: MinglitColors.success,
        ),
      ],
    );
  }
}
