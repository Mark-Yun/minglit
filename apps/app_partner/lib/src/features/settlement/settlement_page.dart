import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class SettlementPage extends ConsumerWidget {
  const SettlementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerDashboardControllerProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '정산 관리'),
      body: MinglitAsyncValueWidget(
        value: state.status,
        data: (_) => RefreshIndicator(
          onRefresh: () => ref
              .read(partnerDashboardControllerProvider.notifier)
              .loadDashboardData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _RevenueSummarySection(summary: state.revenueSummary),
                const SizedBox(height: MinglitSpacing.large),
                _RevenueTrendSection(monthlyRevenue: state.monthlyRevenue),
                const SizedBox(height: MinglitSpacing.large),
                _SettlementListSection(settlements: state.settlements),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
              padding: const EdgeInsets.symmetric(horizontal: 6),
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
          padding: const EdgeInsets.only(top: 6),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
