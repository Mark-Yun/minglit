part of 'settlement_page.dart';

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashState = ref.watch(settlementDashboardControllerProvider);

    return RefreshIndicator(
      onRefresh: () => ref
          .read(settlementDashboardControllerProvider.notifier)
          .loadDashboard(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PeriodSelector(
              selectedMonth: dashState.selectedMonth,
              onChanged: (delta) => ref
                  .read(settlementDashboardControllerProvider.notifier)
                  .changeMonth(delta),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            ...dashState.status.when(
              data: (_) => [
                _RevenueSummaryCard(data: dashState.dashboardData),
                const SizedBox(height: MinglitSpacing.medium),
                _StatusSummaryGrid(data: dashState.dashboardData),
              ],
              loading: () => [const Center(child: CircularProgressIndicator())],
              // Fix #2415: replace inline Column+Text with MinglitEmptyState — aligns with
              // list tab's canonical error pattern; removes raw error.toString() from UI.
              error: (_, _) => [
                MinglitEmptyState(
                  icon: Icons.error_outline,
                  title: '대시보드를 불러오지 못했습니다',
                  subtitle: '잠시 후 다시 시도해 주세요.',
                  actionLabel: '다시 시도',
                  onAction: () => ref
                      .read(settlementDashboardControllerProvider.notifier)
                      .loadDashboard(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({required this.selectedMonth, required this.onChanged});

  final DateTime selectedMonth;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final label = '${selectedMonth.year}년 ${selectedMonth.month}월';
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(-1),
        ),
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(1),
        ),
      ],
    );
  }
}

class _RevenueSummaryCard extends StatelessWidget {
  const _RevenueSummaryCard({required this.data});

  final Map<String, dynamic>? data;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final totalGross = data?['completed_gross_total'] as int? ?? 0;
    final totalNet = data?['completed_net_total'] as int? ?? 0;
    final pendingTotal = data?['pending_gross_total'] as int? ?? 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primary,
            colorScheme.primary.withValues(alpha: MinglitOpacity.scrimLight),
          ],
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fix #1935: completed_gross_total excludes PROCESSING/READY/HOLD
          // — use accurate label so partners aren't misled
          Text(
            '정산 완료 매출',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimary.withValues(
                alpha: MinglitOpacity.scrimLight,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            '₩${fmt.format(totalGross)}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: MinglitSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '정산 완료',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(
                    alpha: MinglitOpacity.scrimDark,
                  ),
                ),
              ),
              Text(
                '₩${fmt.format(totalNet)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '정산 대기',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary.withValues(
                    alpha: MinglitOpacity.scrimDark,
                  ),
                ),
              ),
              Text(
                '₩${fmt.format(pendingTotal)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryGrid extends StatelessWidget {
  const _StatusSummaryGrid({required this.data});

  final Map<String, dynamic>? data;

  static final List<(String, String, SettlementStatus)> _statuses = [
    ('PENDING', '대기', SettlementStatus.pending),
    ('READY', '확정', SettlementStatus.ready),
    ('PROCESSING', '지급중', SettlementStatus.processing),
    ('COMPLETED', '완료', SettlementStatus.completed),
    ('FAILED', '실패', SettlementStatus.failed),
    ('HOLD', '보류', SettlementStatus.hold),
    ('CANCELED', '취소', SettlementStatus.canceled),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final counts = data?['status_counts'] as Map<String, dynamic>? ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태별 현황', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: MinglitSpacing.sm),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: MinglitSpacing.small,
              crossAxisSpacing: MinglitSpacing.small,
              childAspectRatio: 1.2,
              children: _statuses.map((s) {
                final (status, label, statusEnum) = s;
                final count = counts[status] as int? ?? 0;
                return _StatusCell(
                  label: label,
                  count: count,
                  color: statusEnum.textColor(colorScheme),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCell extends StatelessWidget {
  const _StatusCell({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: MinglitOpacity.highlight),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
