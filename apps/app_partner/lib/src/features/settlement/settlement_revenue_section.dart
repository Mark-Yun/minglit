part of 'settlement_page.dart';

class _RevenueSummarySection extends StatelessWidget {
  const _RevenueSummarySection({required this.summary});

  final PartnerRevenueSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('정산 요약', style: theme.textTheme.titleMedium),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: _SummaryItem(
                    label: '총 매출',
                    value: formatter.format(summary.totalSales),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: _SummaryItem(
                    label: '총 환불',
                    value: formatter.format(summary.totalRefunds),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: _SummaryItem(
                    label: '정산 예정액',
                    value: formatter.format(summary.netAmount),
                    isEmphasized: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    this.isEmphasized = false,
  });

  final String label;
  final String value;
  final bool isEmphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isEmphasized ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _RevenueTrendSection extends StatelessWidget {
  const _RevenueTrendSection({required this.monthlyRevenue});

  final List<PartnerMonthlyRevenue> monthlyRevenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = monthlyRevenue.length > 6
        ? monthlyRevenue.sublist(monthlyRevenue.length - 6)
        : monthlyRevenue;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('매출 추이', style: theme.textTheme.titleMedium),
            const SizedBox(height: MinglitSpacing.medium),
            if (entries.isEmpty)
              Text(
                '아직 매출 데이터가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              _RevenueBarChart(entries: entries),
          ],
        ),
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.entries});

  final List<PartnerMonthlyRevenue> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.compact(locale: 'ko_KR');
    final maxValue = entries
        .map((entry) => entry.netAmount)
        .fold<int>(0, (prev, value) => value > prev ? value : prev);

    return SizedBox(
      height: 170,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: entries.map((entry) {
          final ratio = maxValue == 0 ? 0.0 : entry.netAmount / maxValue;
          final barHeight = 110 * ratio;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.xsmall2,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    formatter.format(entry.netAmount),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 110,
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: barHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('M월').format(entry.month),
                    style: theme.textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
