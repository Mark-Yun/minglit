import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class AppliedFiltersRow extends ConsumerWidget {
  const AppliedFiltersRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activeFiltersProvider);
    if (!filters.hasActiveFilters) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (filters.eligibilityEnabled) {
      chips.add(
        _RemovableChip(
          label: '참여 가능',
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.eligibility),
        ),
      );
    }

    if (filters.nearbyEnabled) {
      chips.add(
        _RemovableChip(
          label: '가까운 거리',
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.nearby),
        ),
      );
    }

    if (filters.sortType != ExploreSortType.recommended) {
      final sortLabel = switch (filters.sortType) {
        ExploreSortType.closingSoon => '마감임박순',
        ExploreSortType.nearestDate => '가까운날짜순',
        ExploreSortType.recommended => '',
      };
      chips.add(
        _RemovableChip(
          label: sortLabel,
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.sort),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.xsmall,
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < chips.length; i++) ...[
                    if (i > 0) const SizedBox(width: MinglitSpacing.xsmall),
                    chips[i],
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: MinglitSpacing.small),
          GestureDetector(
            onTap: () => ref.read(activeFiltersProvider.notifier).clearAll(),
            child: Text(
              '초기화',
              style: theme.textTheme.labelSmall?.copyWith(
                color: MinglitColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemovableChip extends StatelessWidget {
  const _RemovableChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MinglitColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: MinglitColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: MinglitColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close,
              size: 14,
              color: MinglitColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
