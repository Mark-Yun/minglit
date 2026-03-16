import 'dart:async';

import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/features/settlement/settlement_models.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_card.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_empty_state.dart';
import 'package:app_partner/src/features/settlement/widgets/status_filter_chips.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'settlement_revenue_section.dart';
part 'settlement_list_section.dart';

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

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      child: Column(
        children: [
          Center(child: Text('대시보드 (Task 6에서 구현)')),
          Offstage(
            child: _RevenueSummarySection(summary: PartnerRevenueSummary()),
          ),
          Offstage(
            child: _RevenueTrendSection(monthlyRevenue: []),
          ),
          Offstage(
            child: _SettlementListSection(settlements: []),
          ),
        ],
      ),
    );
  }
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
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemCount: _items.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i >= _items.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = _items[i];
                      return SettlementCard(
                        item: item,
                        onTap: () {
                          final id = item['id'] as String?;
                          if (id != null) {
                            SettlementDetailRoute(id: id).go(context);
                          }
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
