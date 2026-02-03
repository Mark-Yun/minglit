import 'dart:async';

import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Horizontal row of 4 category chips for quick navigation.
class CategoryChipBar extends StatelessWidget {
  const CategoryChipBar({super.key});

  static const List<(EventFeedType, IconData, String)> _categories = [
    (EventFeedType.nearest, Icons.near_me, '내 주변'),
    (EventFeedType.newArrivals, Icons.fiber_new, '신규 오픈'),
    (EventFeedType.closingSoon, Icons.timer, '마감 임박'),
    (EventFeedType.earlyBird, Icons.local_offer, '얼리버드'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.medium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _categories.map((cat) {
          return _CategoryItem(type: cat.$1, icon: cat.$2, label: cat.$3);
        }).toList(),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({
    required this.type,
    required this.icon,
    required this.label,
  });

  final EventFeedType type;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        unawaited(EventCurationRoute(type: type).push<void>(context));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: MinglitSpacing.large,
            backgroundColor: MinglitColors.primary.withValues(alpha: 0.1),
            child: Icon(
              icon,
              color: MinglitColors.primary,
              size: MinglitIconSize.medium,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: MinglitColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
