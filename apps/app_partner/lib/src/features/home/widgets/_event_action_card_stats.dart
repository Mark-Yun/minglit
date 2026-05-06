part of 'event_action_card.dart';

class _EndedStatsRow extends StatelessWidget {
  const _EndedStatsRow({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final capacity = event.maxParticipants;
    final current = event.currentParticipants;
    final fmt = NumberFormat('#,###');
    // Fix #523: 하드코딩 매출 0 → 실제 티켓 매출 계산
    final totalRevenue =
        event.tickets?.fold<int>(
          0,
          (sum, ticket) => sum + (ticket.price * ticket.soldCount),
        ) ??
        0;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.input),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          _StatCell(label: '참석 확정', value: '$current명', theme: theme),
          // Fix #523: 하드코딩 매출 0 → 실제 티켓 매출 계산
          _StatCell(
            label: '매출',
            value: '₩${fmt.format(totalRevenue)}',
            theme: theme,
          ),
          _StatCell(
            label: '출석률',
            value: capacity > 0
                ? '${(current / capacity * 100).round()}%'
                : '-',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.theme,
  });
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MinglitSpacing.small,
          horizontal: MinglitSpacing.xsmall,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}
