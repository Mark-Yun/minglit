import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_badge.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_tag.dart';

/// Design catalog tab displaying card and badge widgets.
class CardsSection extends StatelessWidget {
  /// Creates a [CardsSection].
  const CardsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // Material Card elevations
        Text('Card Elevations', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        for (final elevation in [0.0, 1.0, 2.0, 4.0]) ...[
          Card(
            elevation: elevation,
            child: Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Text('Card elevation ${elevation.toInt()}'),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
        ],

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitContentCard
        Text('MinglitContentCard', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(child: Text('기본 카드')),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitContentCard(
          highlighted: true,
          child: Text('highlighted 카드 (primary 보더)'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitTag
        Text('MinglitTag', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitTag(label: '음악', color: MinglitColors.primary),
            MinglitTag(label: '승인', color: MinglitColors.success),
            MinglitTag(label: '대기', color: MinglitColors.warning),
            MinglitTag(label: '취소', color: MinglitColors.error),
            MinglitTag(
              label: '카테고리',
              color: MinglitColors.primary,
              icon: Icons.category,
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.medium),
        Text('Small', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitTag(
              label: '음악',
              color: MinglitColors.primary,
              size: MinglitTagSize.small,
            ),
            MinglitTag(
              label: '승인',
              color: MinglitColors.success,
              size: MinglitTagSize.small,
            ),
            MinglitTag(
              label: '아이콘',
              color: MinglitColors.warning,
              size: MinglitTagSize.small,
              icon: Icons.star,
            ),
          ],
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // MinglitBadge
        Text('MinglitBadge', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const Wrap(
          spacing: MinglitSpacing.small,
          runSpacing: MinglitSpacing.small,
          children: [
            MinglitBadge(label: '승인됨', color: MinglitColors.success),
            MinglitBadge(label: '대기', color: MinglitColors.warning),
            MinglitBadge(label: '거절', color: MinglitColors.error),
            MinglitBadge(label: '정산', color: MinglitColors.primary),
            MinglitBadge(
              label: 'compact',
              color: MinglitColors.primary,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }
}
