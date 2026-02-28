import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class ExploreFilterChipBar extends ConsumerWidget {
  const ExploreFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activeFiltersProvider);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
        ),
        children: [
          // Sort icon prefix
          Padding(
            padding: const EdgeInsets.only(right: MinglitSpacing.xsmall),
            child: Icon(
              Icons.sort,
              size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          // Sort chips — single selection
          _SortChip(
            label: '추천순',
            isSelected: filters.sortType == ExploreSortType.recommended,
            onTap: () => ref
                .read(activeFiltersProvider.notifier)
                .setSortType(ExploreSortType.recommended),
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          _SortChip(
            label: '마감임박',
            isSelected: filters.sortType == ExploreSortType.closingSoon,
            onTap: () => ref
                .read(activeFiltersProvider.notifier)
                .setSortType(ExploreSortType.closingSoon),
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          _SortChip(
            label: '가까운날짜',
            isSelected: filters.sortType == ExploreSortType.nearestDate,
            onTap: () => ref
                .read(activeFiltersProvider.notifier)
                .setSortType(ExploreSortType.nearestDate),
          ),
          // Divider between sort and toggle chips
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: MinglitSpacing.small),
            child: VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 8,
              endIndent: 8,
            ),
          ),
          // Toggle chips
          _ToggleChip(
            label: '가까운 거리',
            icon: Icons.near_me_outlined,
            isSelected: filters.nearbyEnabled,
            onTap: () => _onNearbyTap(context, ref),
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          _ToggleChip(
            label: '참여 가능',
            icon: Icons.check_circle_outline,
            isSelected: filters.eligibilityEnabled,
            onTap: () =>
                ref.read(activeFiltersProvider.notifier).toggleEligibility(),
          ),
        ],
      ),
    );
  }

  Future<void> _onNearbyTap(BuildContext context, WidgetRef ref) async {
    final filters = ref.read(activeFiltersProvider);
    if (!filters.nearbyEnabled) {
      // Check if location is available before enabling
      final location = await ref.read(userLocationProvider.future);
      if (location == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('위치 권한이 필요합니다')),
          );
        }
        return;
      }
    }
    ref.read(activeFiltersProvider.notifier).toggleNearby();
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? MinglitColors.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? MinglitColors.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? MinglitColors.primary
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.xsmall2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? MinglitColors.primary.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.5,
                ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? MinglitColors.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : icon,
              size: 16,
              color: isSelected
                  ? MinglitColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? MinglitColors.primary
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
