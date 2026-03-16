import 'dart:async' show unawaited;

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_card.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_empty_state.dart';
import 'package:app_partner/src/features/settlement/widgets/status_filter_chips.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class SettlementPage extends ConsumerStatefulWidget {
  const SettlementPage({super.key});

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends ConsumerState<SettlementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('정산'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대시보드'),
            Tab(text: '정산 내역'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _ListTab(),
        ],
      ),
    );
  }
}

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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _PeriodSelector(
              selectedMonth: dashState.selectedMonth,
              onChanged: (delta) => ref
                  .read(settlementDashboardControllerProvider.notifier)
                  .changeMonth(delta),
            ),
            const SizedBox(height: 16),
            ...dashState.status.when(
              data: (_) => [
                _RevenueSummaryCard(data: dashState.dashboardData),
                const SizedBox(height: 16),
                _StatusSummaryGrid(data: dashState.dashboardData),
              ],
              loading: () => [const Center(child: CircularProgressIndicator())],
              error: (error, _) => [
                Center(
                  child: Column(
                    children: [
                      Text(
                        '오류가 발생했습니다',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref
                            .read(
                              settlementDashboardControllerProvider.notifier,
                            )
                            .loadDashboard(),
                        child: const Text('다시 시도'),
                      ),
                    ],
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

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.selectedMonth,
    required this.onChanged,
  });

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
    final totalFees = totalGross - totalNet;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('매출 요약', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            _DashRow('총 매출', '₩${fmt.format(totalGross)}'),
            _DashRow('총 수수료', '-₩${fmt.format(totalFees)}'),
            const Divider(),
            _DashRow('정산금', '₩${fmt.format(totalNet)}', bold: true),
          ],
        ),
      ),
    );
  }
}

class _DashRow extends StatelessWidget {
  const _DashRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _StatusSummaryGrid extends StatelessWidget {
  const _StatusSummaryGrid({required this.data});

  final Map<String, dynamic>? data;

  static const _statuses = [
    ('PENDING', '대기', Color(0xFF616161)),
    ('READY', '확정', Color(0xFF1565C0)),
    ('PROCESSING', '지급중', Color(0xFF283593)),
    ('COMPLETED', '완료', Color(0xFF1B5E20)),
    ('FAILED', '실패', Color(0xFFB71C1C)),
    ('HOLD', '보류', Color(0xFFE65100)),
    ('CANCELED', '취소', Color(0xFF9E9E9E)),
  ];

  @override
  Widget build(BuildContext context) {
    final counts = data?['status_counts'] as Map<String, dynamic>? ?? {};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('상태별 현황', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: _statuses.map((s) {
                final (status, label, color) = s;
                final count = counts[status] as int? ?? 0;
                return _StatusCell(label: label, count: count, color: color);
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
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

sealed class _ListItem {
  const _ListItem();
}

class _MonthHeader extends _ListItem {
  const _MonthHeader(this.label);
  final String label;
}

class _CardItem extends _ListItem {
  const _CardItem(this.data);
  final Map<String, dynamic> data;
}

class _ListTab extends ConsumerStatefulWidget {
  const _ListTab();

  @override
  ConsumerState<_ListTab> createState() => _ListTabState();
}

class _ListTabState extends ConsumerState<_ListTab> {
  final _scrollController = ScrollController();
  String? _selectedStatus;
  final _items = <Map<String, dynamic>>[];
  bool _isLoading = false;
  bool _hasMore = true;
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    unawaited(_loadMore());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(_loadMore());
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(settlementRepositoryProvider);
      final partner = await ref.read(currentPartnerInfoProvider.future);
      final partnerId = partner?.id;
      if (partnerId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final newItems = await repo.getSettlementItems(
        partnerId: partnerId,
        status: _selectedStatus,
        offset: _items.length,
      );
      if (mounted) {
        setState(() {
          _items.addAll(
            newItems.map((e) => e.toJson()).toList(),
          );
          _hasMore = newItems.length == _pageSize;
        });
      }
    } on Exception catch (e, st) {
      Log.e('ListTab _loadMore error', e, st);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onStatusChanged(String? status) {
    setState(() {
      _selectedStatus = status;
      _items.clear();
      _hasMore = true;
    });
    unawaited(_loadMore());
  }

  List<_ListItem> _buildViewList() {
    final result = <_ListItem>[];
    String? lastMonth;
    for (final item in _items) {
      final raw = item['created_at'] as String?;
      final dt = raw != null ? DateTime.tryParse(raw) : null;
      if (dt != null) {
        final label = '${dt.year}년 ${dt.month}월';
        if (label != lastMonth) {
          result.add(_MonthHeader(label));
          lastMonth = label;
        }
      }
      result.add(_CardItem(item));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        StatusFilterChips(
          selectedStatus: _selectedStatus,
          onStatusChanged: _onStatusChanged,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _items.isEmpty && !_isLoading
              ? SettlementEmptyState(
                  title: '정산 항목이 없습니다',
                  subtitle: _selectedStatus != null ? '다른 상태를 선택해 보세요.' : null,
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _items.clear();
                      _hasMore = true;
                    });
                    await _loadMore();
                  },
                  child: Builder(
                    builder: (context) {
                      final viewList = _buildViewList();
                      return ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: viewList.length + (_isLoading ? 1 : 0),
                        itemBuilder: (context, i) {
                          if (i >= viewList.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final item = viewList[i];
                          return switch (item) {
                            _MonthHeader(:final label) => _MonthHeaderWidget(
                              label: label,
                            ),
                            _CardItem(:final data) => Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SettlementCard(
                                  item: data,
                                  onTap: () {
                                    final id = data['id'] as String?;
                                    if (id != null) {
                                      SettlementDetailRoute(id: id).go(context);
                                    }
                                  },
                                ),
                                const Divider(height: 1),
                              ],
                            ),
                          };
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _MonthHeaderWidget extends StatelessWidget {
  const _MonthHeaderWidget({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
