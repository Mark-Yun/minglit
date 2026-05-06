import 'package:app_partner/src/features/settlement/settlement_coordinator.dart';
import 'package:app_partner/src/features/settlement/settlement_dashboard_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_list_controller.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_card.dart';
import 'package:app_partner/src/features/settlement/widgets/settlement_status_badge.dart';
import 'package:app_partner/src/features/settlement/widgets/status_filter_chips.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part '_settlement_dashboard_tab.dart';
part '_settlement_list_tab.dart';

class SettlementPage extends ConsumerStatefulWidget {
  const SettlementPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends ConsumerState<SettlementPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fix #1568: gate bank-account entry on SETTLEMENT_EDIT permission
    final permissions =
        ref.watch(currentMemberPermissionsProvider).asData?.value ?? [];
    final canEditSettlement = permissions.contains('SETTLEMENT_EDIT');

    return Scaffold(
      appBar: AppBar(
        title: const Text('정산'),
        actions: [
          if (canEditSettlement)
            IconButton(
              key: const Key('bankAccountButton'),
              icon: const Icon(Icons.account_balance_wallet_outlined),
              tooltip: '계좌 관리',
              onPressed: () => ref
                  .read(settlementCoordinatorProvider.notifier)
                  .goToBankAccount(),
            ),
        ],
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
        children: const [_DashboardTab(), _ListTab()],
      ),
    );
  }
}
