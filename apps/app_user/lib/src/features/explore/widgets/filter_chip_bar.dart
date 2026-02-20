import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class ExploreFilterChipBar extends ConsumerWidget {
  const ExploreFilterChipBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(activeFiltersProvider);
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
        ),
        children: [
          _FilterChip(
            label: '참여 가능',
            icon: Icons.check_circle_outline,
            isSelected: filters.eligibilityEnabled,
            onTap: () {
              ref.read(activeFiltersProvider.notifier).toggleEligibility();
            },
          ),
          const SizedBox(width: MinglitSpacing.small),
          _FilterChip(
            label: '위치',
            icon: Icons.location_on_outlined,
            isSelected: filters.locationRadiusMeters != null,
            onTap: () => _showLocationDialog(context, ref),
          ),
          const SizedBox(width: MinglitSpacing.small),
          _FilterChip(
            label: '가격',
            icon: Icons.attach_money,
            isSelected: filters.priceMin != null || filters.priceMax != null,
            onTap: () => _showPriceDialog(context, ref),
          ),
          const SizedBox(width: MinglitSpacing.small),
          _FilterChip(
            label: '날짜',
            icon: Icons.calendar_today_outlined,
            isSelected: filters.dateStart != null || filters.dateEnd != null,
            onTap: () => _showDateDialog(context, ref),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog(BuildContext context, WidgetRef ref) {
    final filters = ref.read(activeFiltersProvider);
    final currentRadius = filters.locationRadiusMeters;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return _LocationFilterSheet(
          currentRadius: currentRadius,
          onSelect: (radius) {
            ref.read(activeFiltersProvider.notifier).setLocationRadius(radius);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showPriceDialog(BuildContext context, WidgetRef ref) {
    final filters = ref.read(activeFiltersProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return _PriceFilterSheet(
          currentMin: filters.priceMin,
          currentMax: filters.priceMax,
          onSelect: ({int? min, int? max}) {
            ref
                .read(activeFiltersProvider.notifier)
                .setPriceRange(min: min, max: max);
            Navigator.pop(context);
          },
        );
      },
    );
  }

  void _showDateDialog(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      ref
          .read(activeFiltersProvider.notifier)
          .setDateRange(
            start: picked.start,
            end: picked.end,
          );
    }
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              icon,
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

class _LocationFilterSheet extends StatelessWidget {
  const _LocationFilterSheet({
    required this.currentRadius,
    required this.onSelect,
  });

  final int? currentRadius;
  final void Function(int?) onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [
      (null, '전체'),
      (1000, '1km 이내'),
      (3000, '3km 이내'),
      (5000, '5km 이내'),
      (10000, '10km 이내'),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Text(
              '위치 필터',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...options.map((opt) {
            final (radius, label) = opt;
            return ListTile(
              title: Text(label),
              trailing: currentRadius == radius
                  ? const Icon(Icons.check, color: MinglitColors.primary)
                  : null,
              onTap: () => onSelect(radius),
            );
          }),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

class _PriceFilterSheet extends StatelessWidget {
  const _PriceFilterSheet({
    required this.currentMin,
    required this.currentMax,
    required this.onSelect,
  });

  final int? currentMin;
  final int? currentMax;
  final void Function({int? min, int? max}) onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [
      (null, null, '전체'),
      (0, 0, '무료'),
      (0, 10000, '1만원 이하'),
      (10000, 30000, '1~3만원'),
      (30000, 50000, '3~5만원'),
      (50000, null, '5만원 이상'),
    ];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Text(
              '가격 필터',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...options.map((opt) {
            final (min, max, label) = opt;
            final isSelected = currentMin == min && currentMax == max;
            return ListTile(
              title: Text(label),
              trailing: isSelected
                  ? const Icon(Icons.check, color: MinglitColors.primary)
                  : null,
              onTap: () => onSelect(min: min, max: max),
            );
          }),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}
