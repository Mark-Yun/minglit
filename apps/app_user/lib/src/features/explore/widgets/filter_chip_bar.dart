import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class ExploreFilterChipBar extends ConsumerWidget {
  const ExploreFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activeFiltersProvider);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
        ),
        children: [
          // Sort chips — single selection
          // Sort chips — single selection
          MinglitFilterChip(
            label: '추천순',
            icon: Icons.local_fire_department,
            isSelected: filters.sortType == ExploreSortType.recommended,
            onTap: () => ref
                .read(activeFiltersProvider.notifier)
                .setSortType(ExploreSortType.recommended),
          ),
          const SizedBox(width: MinglitSpacing.small),
          MinglitFilterChip(
            label: '마감임박',
            icon: Icons.hourglass_bottom,
            isSelected: filters.sortType == ExploreSortType.closingSoon,
            onTap: () => ref
                .read(activeFiltersProvider.notifier)
                .setSortType(ExploreSortType.closingSoon),
          ),
          const SizedBox(width: MinglitSpacing.small),
          MinglitFilterChip(
            label: '가까운날짜',
            icon: Icons.event,
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
          MinglitFilterChip(
            label: '가까운 거리',
            icon: Icons.near_me_outlined,
            isSelected: filters.nearbyEnabled,
            onTap: () => _onNearbyTap(context, ref),
          ),
          const SizedBox(width: MinglitSpacing.small),
          MinglitFilterChip(
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
