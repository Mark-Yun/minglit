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

// [mds-change] #2384: AppBar info icon 추가 — settlement_page spec 동기화
const _kSettlementHelpSections = [
  HelpSection(
    title: '정산은 어떻게 진행되나요?',
    body: '이벤트 종료 후 매칭된 참가자 기준으로 정산 금액이 계산돼요. 영업일 기준 7일 내에 등록된 계좌로 입금됩니다.',
  ),
  HelpSection(
    title: '정산 상태는 무엇을 의미하나요?',
    body: '처리중: 정산 계산 중 / 지급대기: 입금 준비 완료 / 정산완료: 계좌 입금 완료를 의미해요.',
  ),
  HelpSection(
    title: '계좌 정보는 어디서 변경하나요?',
    body: '우측 상단 계좌 관리 버튼을 눌러 등록·변경할 수 있어요. 정산 전에 계좌 정보를 정확히 입력해 주세요.',
  ),
];

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
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '정산 가이드',
              sections: _kSettlementHelpSections,
            ),
          ),
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
