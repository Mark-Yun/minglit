import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #1644: RecurrenceManagementScreen 진입 경로 누락 — 반복 규칙 요약 카드 추가
class RecurrenceRuleSummaryCard extends ConsumerWidget {
  const RecurrenceRuleSummaryCard({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleAsync = ref.watch(partyRecurrenceRuleProvider(partyId));

    return ruleAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (rule) {
        if (rule == null || rule.status == RecurrenceStatus.cancelled) {
          return const SizedBox.shrink();
        }
        return _RecurrenceRuleCard(partyId: partyId, rule: rule);
      },
    );
  }
}

class _RecurrenceRuleCard extends ConsumerWidget {
  const _RecurrenceRuleCard({required this.partyId, required this.rule});

  final String partyId;
  final RecurrenceRule rule;

  static const _dayLabels = {
    0: '일',
    1: '월',
    2: '화',
    3: '수',
    4: '목',
    5: '금',
    6: '토',
  };

  String _buildSummaryText() {
    final patternLabel = switch (rule.pattern) {
      RecurrencePattern.weekly => '매주',
      RecurrencePattern.biweekly => '격주',
      RecurrencePattern.monthly => '매월',
    };

    final periodPart = switch (rule.pattern) {
      RecurrencePattern.weekly || RecurrencePattern.biweekly => () {
        if (rule.daysOfWeek.isEmpty) return patternLabel;
        final days = rule.daysOfWeek
            .map((d) => _dayLabels[d] ?? '')
            .where((s) => s.isNotEmpty)
            .join(', ');
        return '$patternLabel $days';
      }(),
      RecurrencePattern.monthly => () {
        final day = rule.monthDay;
        return day != null ? '$patternLabel ${day}일' : patternLabel;
      }(),
    };

    final timePart = rule.startTime.length >= 5
        ? rule.startTime.substring(0, 5)
        : rule.startTime;

    return '$periodPart · $timePart';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final coordinator = ref.read(partyDetailCoordinatorProvider);

    final (statusLabel, statusColor) = switch (rule.status) {
      RecurrenceStatus.active => ('활성', theme.colorScheme.primary),
      RecurrenceStatus.paused => ('일시 정지', theme.colorScheme.tertiary),
      RecurrenceStatus.cancelled => ('취소됨', theme.colorScheme.error),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.large),
      child: Semantics(
        label:
            '반복 규칙 요약, ${_buildSummaryText()}, 상태 $statusLabel, 관리 화면으로 이동',
        child: Card(
          child: InkWell(
            onTap: () => coordinator.goToRecurrenceManagement(partyId),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.small,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_repeat,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _buildSummaryText(),
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        MinglitTag(label: statusLabel, color: statusColor),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
