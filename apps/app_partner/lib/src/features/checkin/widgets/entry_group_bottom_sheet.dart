import 'package:app_partner/src/features/checkin/stats/entry_group_checkin_stats_controller.dart';
import 'package:app_partner/src/features/checkin/widgets/entry_group_row.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// 엔트리 그룹별 체크인 현황 바텀시트.
///
/// - 축소: 56pt 핸들 + 타이틀 + 서브타이틀 요약
/// - 확장: 그룹 목록 (완충률 순 정렬)
/// - 빈 상태: SizedBox.shrink()
// Fix #1811: Phase 3 — 엔트리 그룹별 체크인 현황 DraggableScrollableSheet
class EntryGroupBottomSheet extends ConsumerWidget {
  const EntryGroupBottomSheet({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(
      entryGroupCheckinStatsControllerProvider(eventId),
    );

    return groupsAsync.when(
      loading: () => const _CollapsedShell(subtitle: '불러오는 중...'),
      error: (e, _) => _CollapsedShell(
        subtitle: '불러오기 실패 · 다시 시도',
        onTap: () => ref.invalidate(
          entryGroupCheckinStatsControllerProvider(eventId),
        ),
      ),
      data: (groups) {
        if (groups.isEmpty) return const SizedBox.shrink();
        final sorted = _sortGroups(groups);
        return _Sheet(groups: sorted);
      },
    );
  }

  static List<EntryGroupCheckinStats> _sortGroups(
    List<EntryGroupCheckinStats> groups,
  ) {
    int bucket(EntryGroupCheckinStats g) {
      final r = g.ratio;
      if (r >= 0.9) return 0;
      if (r >= 0.5) return 1;
      return 2;
    }

    return [...groups]..sort((a, b) {
      final bd = bucket(a).compareTo(bucket(b));
      return bd != 0 ? bd : a.label.compareTo(b.label);
    });
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.groups});

  final List<EntryGroupCheckinStats> groups;

  String get _subtitle {
    return groups
        .map((g) => '${g.label} ${g.checkedIn}/${g.total}')
        .join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.08,
      maxChildSize: 0.85,
      snap: true,
      snapSizes: const [0.12, 0.85],
      builder: (context, scrollController) {
        return _SheetContent(
          groups: groups,
          subtitle: _subtitle,
          scrollController: scrollController,
        );
      },
    );
  }
}

class _SheetContent extends StatelessWidget {
  const _SheetContent({
    required this.groups,
    required this.subtitle,
    required this.scrollController,
  });

  final List<EntryGroupCheckinStats> groups;
  final String subtitle;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(MinglitRadius.card),
      ),
      child: Column(
        children: [
          // 드래그 핸들
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // 헤더 (타이틀 + 서브타이틀)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '엔트리 그룹별 현황',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_up,
                  size: 14,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // 그룹 목록 (확장 시 표시)
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.screenEdge,
              ),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                return Semantics(
                  label:
                      '${groups[index].label}, ${groups[index].checkedIn}명 체크인, '
                      '총 ${groups[index].total}명 중, '
                      '${(groups[index].ratio * 100).toStringAsFixed(0)}퍼센트',
                  child: EntryGroupRow(
                    stats: groups[index],
                    showDivider: index < groups.length - 1,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CollapsedShell extends StatelessWidget {
  const _CollapsedShell({
    required this.subtitle,
    this.onTap,
  });

  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.12,
      minChildSize: 0.08,
      maxChildSize: 0.12,
      builder: (context, scrollController) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;

        return GestureDetector(
          onTap: onTap,
          child: Material(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(MinglitRadius.card),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.screenEdge,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '엔트리 그룹별 현황',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: scheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
