import 'package:flutter/material.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/card_layouts_demo.dart';
import 'package:minglit_kit/src/features/dev/catalog_tabs/patterns/detail_page_demo.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_content_card.dart';

/// Pattern catalog listing section.
///
/// Displays all available pattern demos grouped by category.
/// Each item navigates to its corresponding full-screen demo.
class PatternListSection extends StatelessWidget {
  /// Creates a [PatternListSection].
  const PatternListSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      children: [
        Text('페이지 패턴', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        _PatternTile(
          title: 'P1 — 상세 페이지',
          subtitle: 'Hero + TabBar + CTA 구조',
          icon: Icons.article_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const DetailPageDemo()),
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('상태 패턴', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const _PatternTile(
          title: 'P6 — 빈/에러/로딩 상태',
          subtitle: '3단계 로딩 + 빈/에러 표준 구조',
          icon: Icons.hourglass_empty_outlined,
          onTap: null, // feat/715 — 준비 중
          disabled: true,
        ),
        const _PatternTile(
          title: 'P7 — Async 래퍼',
          subtitle: 'MinglitAsyncValueWidget 사용법',
          icon: Icons.sync_outlined,
          onTap: null, // feat/716 — 준비 중
          disabled: true,
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('데이터 표시 패턴', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        _PatternTile(
          title: 'P4 — 카드 레이아웃',
          subtitle: '5가지 카드 변형 프리뷰',
          icon: Icons.grid_view_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (_) => const CardLayoutsDemo()),
          ),
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text('트랜잭션 패턴', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.small),
        const _PatternTile(
          title: 'P5 — 결제 플로우',
          subtitle: '결제/환불 상태 시뮬레이션',
          icon: Icons.payment_outlined,
          onTap: null, // feat/717 — 준비 중
          disabled: true,
        ),
      ],
    );
  }
}

class _PatternTile extends StatelessWidget {
  const _PatternTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: MinglitContentCard(
        child: ListTile(
          leading: Icon(
            icon,
            color: disabled
                ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                : MinglitColors.primary,
          ),
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              color: disabled
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                  : null,
            ),
          ),
          subtitle: Text(subtitle),
          trailing: disabled
              ? Chip(
                  label: const Text('준비 중'),
                  labelStyle: theme.textTheme.labelSmall,
                  padding: EdgeInsets.zero,
                )
              : const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}
