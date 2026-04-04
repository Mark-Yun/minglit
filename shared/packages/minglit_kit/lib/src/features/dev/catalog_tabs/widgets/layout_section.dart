import 'package:flutter/material.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_key_value_row.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_list_tile.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_section_divider.dart';

/// Design catalog tab displaying layout widgets.
class LayoutSection extends StatelessWidget {
  /// Creates a [LayoutSection].
  const LayoutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleLarge = theme.textTheme.titleLarge;

    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        // 1. MinglitSection
        Text('MinglitSection', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitSection(
          title: '참여 현황',
          child: Text('섹션 콘텐츠가 여기에'),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitSection(
          title: '이번 주 성과',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('더보기'),
          ),
          child: const Text('trailing 액션 포함'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 2. MinglitContentCard
        Text('MinglitContentCard', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitContentCard(
          child: Column(
            children: [
              Text('기본 카드'),
              Text('내부 패딩과 radius가 통일됩니다'),
            ],
          ),
        ),
        const SizedBox(height: MinglitSpacing.sm),
        const MinglitContentCard(
          highlighted: true,
          child: Text('highlighted 카드 (primary 보더)'),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 3. MinglitKeyValueRow
        Text('MinglitKeyValueRow', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitContentCard(
          child: Column(
            children: [
              MinglitKeyValueRow(label: '총 매출', value: '₩420,000'),
              MinglitKeyValueRow(label: '수수료', value: '-₩42,000'),
              Divider(),
              MinglitKeyValueRow(
                label: '정산금',
                value: '₩378,000',
                bold: true,
              ),
            ],
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 4. MinglitSectionDivider
        Text('MinglitSectionDivider', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        Text('thick (8px)', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Text('Content above'),
        const MinglitSectionDivider.thick(),
        const Text('Content below'),
        const SizedBox(height: MinglitSpacing.large),
        Text('thin (1px)', style: theme.textTheme.titleSmall),
        const SizedBox(height: MinglitSpacing.small),
        const Text('Content above'),
        const MinglitSectionDivider.thin(),
        const Text('Content below'),

        const Divider(height: MinglitSpacing.xxlarge),

        // 5. 조합 예시
        Text('조합 예시', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitSection(
          title: '정산 요약',
          trailing: TextButton(
            onPressed: () {},
            child: const Text('상세 ›'),
          ),
          child: const MinglitContentCard(
            child: Column(
              children: [
                MinglitKeyValueRow(
                  label: '이번 달',
                  value: '₩1,280,000',
                  bold: true,
                ),
                MinglitKeyValueRow(
                  label: '정산 완료',
                  value: '₩850,000',
                ),
                MinglitKeyValueRow(
                  label: '정산 대기',
                  value: '₩430,000',
                ),
              ],
            ),
          ),
        ),

        const Divider(height: MinglitSpacing.xxlarge),

        // 5. MinglitListTile
        Text('MinglitListTile', style: titleLarge),
        const SizedBox(height: MinglitSpacing.medium),
        const MinglitListTile(title: '기본 타일 (title only)'),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitListTile(
          title: '홍길동',
          subtitle: '파트너 매니저',
        ),
        const SizedBox(height: MinglitSpacing.small),
        MinglitListTile(
          title: '아바타 + trailing',
          subtitle: '네트워크 이미지 예시',
          avatar: const AssetImage(
            'packages/minglit_kit/assets/images/minglit_app_bar_logo.png',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {},
        ),
        const SizedBox(height: MinglitSpacing.small),
        const MinglitListTile(
          title: '비활성 타일',
          subtitle: 'enabled: false',
          leading: Icon(Icons.block),
          enabled: false,
        ),
      ],
    );
  }
}
