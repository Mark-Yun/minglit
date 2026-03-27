import 'dart:async' show unawaited;

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/widgets/event_action_card.dart';
import 'package:app_partner/src/features/home/widgets/onboarding_step_guide.dart';
import 'package:app_partner/src/features/home/widgets/todo_summary_chips.dart';
import 'package:app_partner/src/features/home/widgets/weekly_stats_row.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO(#519): partnerDashboardControllerProvider loads all sections in a
    // single async call. Consider splitting into per-section providers for
    // independent loading states (e.g. events, stats, applications).
    final state = ref.watch(partnerDashboardControllerProvider);
    final partner = ref.watch(currentPartnerInfoProvider).value;
    final unreadCount = ref
        .watch(notificationListProvider)
        // ignore: use_minglit_async_value_widget, extracts int count not a Widget
        .maybeWhen(
          data: (notifications) => notifications
              .where((n) => !(n['is_read'] as bool? ?? false))
              .length,
          orElse: () => 0,
        );
    final coordinator = ref.read(partnerHomeCoordinatorProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: MinglitTheme.appBarLogo(height: 28),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                tooltip: '알림 센터',
                onPressed: coordinator.pushNotificationCenter,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.xsmall2,
                      vertical: MinglitSpacing.xxsmall,
                    ),
                    decoration: BoxDecoration(
                      color: MinglitColors.error,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: theme.colorScheme.surface,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: theme.textTheme.bodySmall!.copyWith(
                        color: MinglitColors.background,
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
        data: (_) {
          // Onboarding: show step guide if no events yet
          final hasEvents = state.upcomingEvents.isNotEmpty;
          final hasParties = state.activeParties.isNotEmpty;
          final showOnboarding = !hasEvents;

          return RefreshIndicator(
            onRefresh: () => ref
                .read(partnerDashboardControllerProvider.notifier)
                .loadDashboardData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showOnboarding) ...[
                    // Onboarding Step Guide
                    _GreetingSection(
                      partnerName: partner?.name ?? '파트너',
                      pendingCount: 0,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    OnboardingStepGuide(
                      hasParty: hasParties,
                      partyName: hasParties
                          ? state.activeParties.first.title
                          : null,
                      onCreateParty: () {
                        unawaited(
                          const PartyCreateRoute().push<void>(context),
                        );
                      },
                      onCreateEvent: () async {
                        final parties = state.activeParties;
                        if (parties.length == 1) {
                          unawaited(
                            EventCreateRoute(
                              partyId: parties.first.id,
                            ).push<void>(context),
                          );
                          return;
                        }
                        final selected = await showModalBottomSheet<Party>(
                          context: context,
                          builder: (ctx) =>
                              _PartySelectionSheet(parties: parties),
                        );
                        if (selected != null && context.mounted) {
                          unawaited(
                            EventCreateRoute(
                              partyId: selected.id,
                            ).push<void>(context),
                          );
                        }
                      },
                    ),
                  ] else ...[
                    // Normal Dashboard
                    // 1. Greeting
                    _GreetingSection(
                      partnerName: partner?.name ?? '파트너',
                      pendingCount: state.pendingReviewCount,
                      primaryEvent: selectPrimaryEvent(state.upcomingEvents),
                    ),
                    const SizedBox(height: MinglitSpacing.medium),

                    // 2. Todo Summary Chips
                    TodoSummaryChips(
                      pendingApplications: state.pendingReviewCount,
                      upcomingEvents: state.upcomingEvents.length,
                      onPendingTap: () {
                        const ApplicationListRoute().go(context);
                      },
                      onUpcomingTap: () {
                        unawaited(
                          const PartyListRoute().push<void>(context),
                        );
                      },
                    ),
                    const SizedBox(height: MinglitSpacing.large),

                    // 3. Event Action Card
                    _buildEventSection(context, ref, state),
                    const SizedBox(height: MinglitSpacing.large),

                    // 4. Weekly Stats
                    const _SectionHeader(title: '이번 주 성과'),
                    const SizedBox(height: MinglitSpacing.small),
                    // TODO(#519): wire real weekly stats APIs — values
                    // below are placeholders and should NOT be used for
                    // KPI reporting until the backend endpoint is ready.
                    WeeklyStatsRow(
                      totalRevenue: null,
                      totalApplications: state.pendingReviewCount,
                      checkinRate: null,
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventSection(
    BuildContext context,
    WidgetRef ref,
    PartnerDashboardState state,
  ) {
    final primaryEvent = selectPrimaryEvent(state.upcomingEvents);

    final sectionTitle = switch (primaryEvent != null
        ? getEventPhase(primaryEvent)
        : null) {
      EventPhase.recruiting => '다음 이벤트',
      EventPhase.preparing => '오늘 이벤트',
      EventPhase.live => '진행 중 이벤트',
      EventPhase.ended => '이벤트 결과',
      null => null,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (sectionTitle != null) ...[
          _SectionHeader(title: sectionTitle),
          const SizedBox(height: MinglitSpacing.small),
        ],
        _buildEventActionCard(context, ref, state, primaryEvent),
      ],
    );
  }

  Widget _buildEventActionCard(
    BuildContext context,
    WidgetRef ref,
    PartnerDashboardState state,
    Event? primaryEvent,
  ) {
    if (primaryEvent == null) {
      return EventActionCardEmpty(
        hasParties: state.activeParties.isNotEmpty,
        onCreateEvent: () async {
          final parties = state.activeParties;
          if (parties.isEmpty) return;
          if (parties.length == 1) {
            unawaited(
              EventCreateRoute(partyId: parties.first.id).push<void>(context),
            );
            return;
          }
          final selected = await showModalBottomSheet<Party>(
            context: context,
            builder: (ctx) => _PartySelectionSheet(parties: parties),
          );
          if (selected != null && context.mounted) {
            unawaited(
              EventCreateRoute(partyId: selected.id).push<void>(context),
            );
          }
        },
        onCreateParty: () {
          unawaited(const PartyCreateRoute().push<void>(context));
        },
      );
    }

    final phase = getEventPhase(primaryEvent);
    return EventActionCard(
      event: primaryEvent,
      onMainAction: () {
        switch (phase) {
          case EventPhase.recruiting:
            const ApplicationListRoute().go(context);
          case EventPhase.preparing:
          case EventPhase.live:
            const CheckinRoute().go(context);
          case EventPhase.ended:
            // "다음 회차 만들기" → 이벤트 생성 (pre-fill은 #520에서 구현)
            unawaited(
              EventCreateRoute(
                partyId: primaryEvent.partyId,
              ).push<void>(context),
            );
        }
      },
      onSecondaryAction1: () {
        switch (phase) {
          case EventPhase.recruiting:
            unawaited(
              EventDetailRoute(
                partyId: primaryEvent.partyId,
                eventId: primaryEvent.id,
              ).push<void>(context),
            );
          case EventPhase.preparing:
          case EventPhase.live:
            unawaited(
              EventDetailRoute(
                partyId: primaryEvent.partyId,
                eventId: primaryEvent.id,
              ).push<void>(context),
            );
          case EventPhase.ended:
            unawaited(
              EventDetailRoute(
                partyId: primaryEvent.partyId,
                eventId: primaryEvent.id,
              ).push<void>(context),
            );
        }
      },
      onSecondaryAction2:
          phase == EventPhase.recruiting || phase == EventPhase.preparing
          ? () {
              // 공유/홍보 or 안내 발송 — placeholder
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('준비 중입니다')),
              );
            }
          : null,
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.partnerName,
    required this.pendingCount,
    this.primaryEvent,
  });

  final String partnerName;
  final int pendingCount;
  final Event? primaryEvent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = primaryEvent != null ? getEventPhase(primaryEvent!) : null;

    final subtitle = switch (phase) {
      EventPhase.live => '이벤트 진행 중!',
      EventPhase.ended => '오늘 이벤트 수고하셨어요!',
      _ when pendingCount > 0 => '오늘 할 일 $pendingCount건',
      _ => '오늘 할 일 없음',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '👋 $partnerName 님',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PartySelectionSheet extends StatelessWidget {
  const _PartySelectionSheet({required this.parties});
  final List<Party> parties;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Text(
              '파티 선택',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...parties.map(
            (party) => ListTile(
              title: Text(party.title),
              onTap: () => Navigator.of(context).pop(party),
            ),
          ),
        ],
      ),
    );
  }
}
