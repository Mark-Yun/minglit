import 'package:app_user/src/features/tag/logic/tag_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A horizontally scrollable section showing trending tags.
///
/// Hidden entirely when the trending tags list is empty.
class TrendingTagSection extends ConsumerWidget {
  const TrendingTagSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(trendingTagsProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: Text(
                '🔥 핫 태그',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                itemCount: tags.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: MinglitSpacing.small),
                itemBuilder: (context, index) {
                  final tag = tags[index];
                  return _TrendingTagCard(
                    tagId: tag.id,
                    tagName: tag.name,
                    usageCount: tag.usageCount,
                    onTap: () => ref
                        .read(tagCoordinatorProvider)
                        .goToTagEventList(tag.id, tag.name),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _TrendingTagCard extends StatelessWidget {
  const _TrendingTagCard({
    required this.tagId,
    required this.tagName,
    required this.usageCount,
    required this.onTap,
  });

  final String tagId;
  final String tagName;
  final int usageCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final countLabel = NumberFormat('#,###').format(usageCount);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.small,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '#$tagName',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '이벤트 $countLabel개',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
