import 'dart:async';

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/widgets/approval_waiting_card.dart';
import 'package:app_partner/src/features/home/widgets/revenue_summary_card.dart';
import 'package:app_partner/src/features/home/widgets/today_party_card.dart';
import 'package:app_partner/src/features/party/party_providers.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerDashboardControllerProvider);
    final partner = ref.watch(currentPartnerInfoProvider).value;
    final unreadCount = ref
        .watch(notificationListProvider)
        .maybeWhen(
          data: (notifications) => notifications
              .where((n) => !(n['is_read'] as bool? ?? false))
              .length,
          orElse: () => 0,
        );

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: partner?.name ?? '파트너 대시보드',
        showBackButton: false,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: '알림 센터',
                onPressed: () {
                  unawaited(const NotificationCenterRoute().push(context));
                },
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
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
