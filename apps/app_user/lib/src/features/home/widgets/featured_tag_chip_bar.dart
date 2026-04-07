import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A horizontally scrollable bar of featured tag chips.
///
/// Tapping a chip navigates to the tag event list page.
class FeaturedTagChipBar extends ConsumerWidget {
  const FeaturedTagChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(featuredTagsProvider);

    return tagsAsync.when(
      data: (tags) {
        if (tags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 36,
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
              return _TagChip(
                label: tag.name,
                onTap: () => TagEventListRoute(
                  tagId: tag.id,
                  tagName: tag.name,
                ).push<void>(context),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 36),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(MinglitRadius.chip),
        ),
        child: Text(
          '#$label',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
