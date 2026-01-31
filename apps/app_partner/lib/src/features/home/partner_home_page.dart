import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/widgets/approval_waiting_card.dart';
import 'package:app_partner/src/features/home/widgets/revenue_summary_card.dart';
import 'package:app_partner/src/features/home/widgets/today_party_card.dart';
import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerDashboardControllerProvider);
    final partner = ref.watch(currentPartnerInfoProvider).value;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: partner?.name ?? 'Partner Dashboard',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO(developer): Notification Center
            },
          ),
        ],
      ),
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
                // 1. Approval Waiting
                ApprovalWaitingCard(count: state.pendingReviewCount),
                const SizedBox(height: MinglitSpacing.large),

                // 2. Revenue (If permitted)
                if (state.hasRevenuePermission) ...[
                  const RevenueSummaryCard(),
                  const SizedBox(height: MinglitSpacing.large),
                ],

                // 3. Today's Schedule
                TodayPartyCard(events: state.todayEvents),

                const SizedBox(height: 100), // Bottom padding for FAB/Nav
              ],
            ),
          ),
        ),
      ),
    );
  }
}
