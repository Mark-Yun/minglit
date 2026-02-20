import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

    if (filters.locationRadiusMeters != null) {
      final km = filters.locationRadiusMeters! >= 1000
          ? '${filters.locationRadiusMeters! ~/ 1000}km'
          : '${filters.locationRadiusMeters}m';
      chips.add(
        _RemovableChip(
          label: '$km 이내',
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.location),
        ),
      );
    }

    if (filters.priceMin != null || filters.priceMax != null) {
      String priceLabel;
      if (filters.priceMin == 0 && filters.priceMax == 0) {
        priceLabel = '무료';
      } else if (filters.priceMax == null) {
        priceLabel = '${_formatPrice(filters.priceMin!)}+';
      } else {
        priceLabel =
            '${_formatPrice(filters.priceMin ?? 0)}~${_formatPrice(filters.priceMax!)}';
      }
      chips.add(
        _RemovableChip(
          label: priceLabel,
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.price),
        ),
      );
    }

    if (filters.dateStart != null || filters.dateEnd != null) {
      final fmt = DateFormat('M/d');
      final start = filters.dateStart != null
          ? fmt.format(filters.dateStart!)
          : '';
      final end = filters.dateEnd != null ? fmt.format(filters.dateEnd!) : '';
      chips.add(
        _RemovableChip(
          label: '$start~$end',
          onRemove: () => ref
              .read(activeFiltersProvider.notifier)
              .removeFilter(ExploreFilterType.date),
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

  String _formatPrice(int won) {
    if (won >= 10000) return '${won ~/ 10000}만원';
    return '${NumberFormat('#,###').format(won)}원';
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
            child: Icon(
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
