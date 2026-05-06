part of 'event_card.dart';

/// Skeleton loader for event card.
class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fix #1382: 스켈레톤 카드 비율 16:9 → 2:1 통일
          const AspectRatio(
            aspectRatio: 2 / 1,
            child: MinglitSkeleton(borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
              vertical: MinglitSpacing.small,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MinglitSkeleton(width: w * 0.8, height: 16),
                    const SizedBox(height: MinglitSpacing.xsmall),
                    Row(
                      children: [
                        MinglitSkeleton(width: w * 0.5, height: 12),
                        const Spacer(),
                        MinglitSkeleton(width: w * 0.2, height: 12),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
