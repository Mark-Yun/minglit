import 'package:app_partner/src/features/settlement/settlement_controller.dart';
import 'package:app_partner/src/features/settlement/settlement_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

part 'settlement_revenue_section.dart';
part 'settlement_list_section.dart';

class SettlementPage extends ConsumerWidget {
  const SettlementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settlementControllerProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '정산 관리'),
      body: MinglitAsyncValueWidget(
        value: state.status,
        data: (_) => RefreshIndicator(
          onRefresh: () => ref
              .read(settlementControllerProvider.notifier)
              .loadSettlementData(),
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
