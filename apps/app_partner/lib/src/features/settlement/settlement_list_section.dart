part of 'settlement_page.dart';

class _SettlementListSection extends StatelessWidget {
  const _SettlementListSection({required this.settlements});

  final List<PartnerSettlement> settlements;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('이벤트별 정산', style: theme.textTheme.titleMedium),
        const SizedBox(height: MinglitSpacing.medium),
        if (settlements.isEmpty)
          Text(
            '완료된 이벤트가 아직 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else
          ...settlements.map((settlement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
              child: _SettlementCard(settlement: settlement),
            );
          }),
      ],
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.settlement});

  final PartnerSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
    final dateFormatter = DateFormat('yyyy.MM.dd');
    final badge = _StatusBadge(status: settlement.status);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(MinglitSpacing.medium),
        childrenPadding: const EdgeInsets.fromLTRB(
          MinglitSpacing.medium,
          0,
          MinglitSpacing.medium,
          MinglitSpacing.medium,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                settlement.eventTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            badge,
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: MinglitSpacing.xsmall2),
          child: Text(
            '${dateFormatter.format(settlement.eventDate)} '
            '· 정산 예정액 ${formatter.format(settlement.netAmount)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        children: [
          _FeeRow(
            label: '총 매출',
            value: formatter.format(settlement.totalSales),
          ),
          _FeeRow(
            label: '총 환불',
            value: formatter.format(settlement.totalRefunds),
          ),
          _FeeRow(
            label: 'PG 수수료 (3.5%)',
            value: formatter.format(settlement.pgFee),
          ),
          _FeeRow(
            label: '플랫폼 수수료 (5%)',
            value: formatter.format(settlement.platformFee),
          ),
          _FeeRow(label: '부가세 (10%)', value: formatter.format(settlement.vat)),
          const Divider(height: MinglitSpacing.large),
          _FeeRow(
            label: '정산 예정액',
            value: formatter.format(settlement.netAmount),
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _FeeRow extends StatelessWidget {
  const _FeeRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xsmall),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              color: emphasize ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final label = _statusLabel(status);
    final color = _statusColor(status, colorScheme);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.small, vertical: MinglitSpacing.xsmall),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ready':
        return '정산 가능';
      case 'requested':
        return '정산 신청됨';
      case 'completed':
        return '정산 완료';
      case 'pending':
      default:
        return '정산 대기';
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'ready':
        return scheme.primary;
      case 'requested':
        return scheme.tertiary;
      case 'completed':
        return scheme.secondary;
      case 'pending':
      default:
        return scheme.onSurfaceVariant;
    }
  }
}
