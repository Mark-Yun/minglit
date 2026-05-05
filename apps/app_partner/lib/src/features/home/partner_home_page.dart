import 'dart:async' show unawaited;

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/widgets/home_approval_pending_card.dart';
import 'package:app_partner/src/features/home/widgets/home_draft_party_card.dart';
import 'package:app_partner/src/features/home/widgets/home_live_event_card.dart';
import 'package:app_partner/src/features/home/widgets/home_overview_block.dart';
import 'package:app_partner/src/features/home/widgets/home_recruiting_event_card.dart';
import 'package:app_partner/src/features/home/widgets/home_section_header.dart';
import 'package:app_partner/src/features/home/widgets/home_upcoming_event_card.dart';
import 'package:app_partner/src/features/home/widgets/location_guide_banner.dart';
import 'package:app_partner/src/features/home/widgets/onboarding_step_guide.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerDashboardControllerProvider);
    final partner = ref.watch(currentPartnerInfoProvider).asData?.value;
    final coordinator = ref.read(partnerHomeCoordinatorProvider);
    final unreadCount = ref
        .watch(notificationListProvider)
        .maybeWhen(
          data: (notifications) => notifications
              .where(
                (notification) => !(notification['is_read'] as bool? ?? false),
              )
              .length,
          orElse: () => 0,
        );

    return Scaffold(
      appBar: AppBar(
        title: MinglitTheme.appBarLogo(height: 36),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Fix #2200: AppBar info → help sheet 패턴 적용
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '파트너 대시보드 가이드',
              sections: const [
                HelpSection(
                  title: '대시보드가 뭔가요?',
                  body: '운영 중인 파티와 이벤트 현황을 한눈에 파악하는 화면이에요. 오늘 처리할 일을 빠르게 찾아요.',
                ),
                HelpSection(
                  title: '진행 중·심사 대기·모집 중이란?',
                  body:
                      '진행 중: 체크인 단계, 심사 대기: pending 신청이 있는 이벤트, '
                      '모집 중: 신청을 받는 이벤트예요.',
                ),
                HelpSection(
                  title: '카드 탭 동작은?',
                  body: '카드를 탭하면 이벤트 상세로 이동해요. 심사 대기 카드는 신청 관리로 바로 이동해요.',
                ),
                HelpSection(
                  title: '체크인은 어디서 하나요?',
                  body: '하단 체크인 탭에서 QR 스캔 또는 수동 체크인을 진행해요.',
                ),
              ],
            ),
          ),
          const BugReportAction(),
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
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.xsmall2,
                      vertical: MinglitSpacing.xxsmall,
                    ),
                    decoration: BoxDecoration(
                      color: MinglitColors.error,
                      borderRadius: BorderRadius.circular(MinglitRadius.button),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: MinglitColors.background,
                        fontWeight: FontWeight.w700,
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
                  _GreetingSection(
                    partnerName: partner?.name ?? '파트너',
                    totalPartyCount: state.totalPartyCount,
                    pendingApplications: state.pendingReviewCount,
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                  if (!state.hasAnyEvents) ...[
                    LocationGuideBanner(onTap: coordinator.pushLocationGuide),
                    const SizedBox(height: MinglitSpacing.medium),
                    OnboardingStepGuide(
                      hasParty: state.activeParties.isNotEmpty,
                      partyName: state.activeParties.firstOrNull?.title,
                      onCreateParty: coordinator.pushPartyCreate,
                      onCreateEvent: () async {
                        if (state.activeParties.length == 1) {
                          coordinator.pushEventCreate(
                            state.activeParties.first.id,
                          );
                          return;
                        }
                        final selected = await showModalBottomSheet<Party>(
                          context: context,
                          builder: (bottomSheetContext) => _PartySelectionSheet(
                            parties: state.activeParties,
                          ),
                        );
                        if (selected != null) {
                          coordinator.pushEventCreate(selected.id);
                        }
                      },
                    ),
                  ] else ...[
                    HomeOverviewBlock(
                      totalPartyCount: state.totalPartyCount,
                      recruitingCount: state.recruitingEvents.length,
                      totalAttendees: state.totalAttendees,
                      onPartiesTap: () {
                        unawaited(const PartyListRoute().push<void>(context));
                      },
                      // spec: 모집 중인 이벤트 → 이벤트 리스트(파티 리스트 경유)
                      onEventsTap: () {
                        unawaited(const PartyListRoute().push<void>(context));
                      },
                      onAttendeesTap: coordinator.goToApplicationList,
                    ),
                    if (state.liveEvents.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '진행 중'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.liveEvents.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeLiveEventCard(
                            event: event,
                            onCheckin: coordinator.goToCheckin,
                          ),
                        ),
                      ),
                    ],
                    if (state.pendingReviewCount > 0) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '심사 대기'),
                      const SizedBox(height: MinglitSpacing.small),
                      HomeApprovalPendingCard(
                        pendingCount: state.pendingReviewCount,
                        onReview: coordinator.goToApplicationList,
                      ),
                    ],
                    if (state.recruitingEvents.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '모집 중인 이벤트'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.recruitingEvents.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeRecruitingEventCard(
                            event: event,
                            pendingCount: 0,
                            onTap: () => coordinator.pushEventDetail(
                              partyId: event.partyId,
                              eventId: event.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (state.preparingEvents.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '준비 중인 이벤트'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.preparingEvents.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeUpcomingEventCard(
                            event: event,
                            onTap: () => coordinator.pushEventDetail(
                              partyId: event.partyId,
                              eventId: event.id,
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (state.draftParties.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '이벤트 없는 파티'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.draftParties.map(
                        (party) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeDraftPartyCard(
                            party: party,
                            onCreateEvent: () =>
                                coordinator.pushEventCreate(party.id),
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GreetingSection extends StatelessWidget {
  const _GreetingSection({
    required this.partnerName,
    required this.totalPartyCount,
    required this.pendingApplications,
  });

  final String partnerName;
  final int totalPartyCount;
  final int pendingApplications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = pendingApplications > 0
        ? '심사 대기 $pendingApplications건을 확인해주세요'
        : '운영 중인 파티 $totalPartyCount개';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$partnerName 님',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PartySelectionSheet extends StatelessWidget {
  const _PartySelectionSheet({required this.parties});

  final List<Party> parties;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.large),
              child: Text(
                '이벤트를 만들 파티를 선택하세요',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ...parties.map(
              (party) => ListTile(
                leading: const Icon(Icons.storefront_outlined),
                title: Text(party.title),
                onTap: () => Navigator.of(context).pop(party),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
