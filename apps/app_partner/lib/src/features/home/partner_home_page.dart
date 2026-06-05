import 'dart:async' show unawaited;

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/widgets/home_approval_pending_card.dart';
import 'package:app_partner/src/features/home/widgets/home_draft_event_card.dart';
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
import 'package:app_partner/src/ui/screens/ongoing_event_list_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// [mds-change] #2384: AppBar info icon 추가 — partner_home_page spec 동기화
const _kHomeHelpSections = [
  HelpSection(
    title: '대시보드에서 무엇을 할 수 있나요?',
    body: '현재 진행 중인 이벤트, 모집 중인 이벤트, 임박한 일정을 한눈에 확인할 수 있어요.',
  ),
  HelpSection(
    title: '이벤트는 어디서 만드나요?',
    body: '하단 탭의 파티 관리에서 파티를 만든 뒤 이벤트를 추가할 수 있어요. 파티는 여러 이벤트를 묶는 단위예요.',
  ),
  HelpSection(
    title: '신청자 관리는 어떻게 하나요?',
    body: '하단 탭의 신청관리에서 대기 중인 신청을 승인하거나 거절할 수 있어요.',
  ),
];

class PartnerHomePage extends ConsumerWidget {
  const PartnerHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partnerDashboardControllerProvider);
    final partner = ref.watch(currentPartnerInfoProvider).asData?.value;
    final coordinator = ref.read(partnerHomeCoordinatorProvider);
    String? partyNameFor(String partyId) {
      for (final party in state.activeParties) {
        if (party.id == partyId) return party.title;
      }
      return null;
    }

    Future<void> openFirstEventCreate() async {
      if (state.activeParties.length == 1) {
        coordinator.pushEventCreate(state.activeParties.first.id);
        return;
      }
      final selected = await showMinglitBottomSheet<Party>(
        context: context,
        title: '이벤트를 만들 파티를 선택하세요',
        child: _PartySelectionSheet(parties: state.activeParties),
      );
      if (selected != null) {
        coordinator.pushEventCreate(selected.id);
      }
    }

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
        // Fix #2354: PARTNER 워드마크 누락 — spec: partner_home_page.html#①
        title: MinglitTheme.partnerAppBarLogo(),
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '파트너 홈 가이드',
              sections: _kHomeHelpSections,
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
                  if (state.hasAnyEvents && !state.bankAccountReady) ...[
                    const SizedBox(height: MinglitSpacing.medium),
                    _BankAccountTodoCard(
                      verificationStatus: state.bankVerificationStatus,
                      onTap: coordinator.pushBankAccount,
                    ),
                  ],
                  const SizedBox(height: MinglitSpacing.medium),
                  if (!state.hasAnyEvents) ...[
                    LocationGuideBanner(onTap: coordinator.pushLocationGuide),
                    const SizedBox(height: MinglitSpacing.medium),
                    OnboardingStepGuide(
                      hasParty: state.activeParties.isNotEmpty,
                      bankAccountReady: state.bankAccountReady,
                      bankVerificationStatus: state.bankVerificationStatus,
                      partyName: state.activeParties.firstOrNull?.title,
                      onOpenBankAccount: coordinator.pushBankAccount,
                      onCreateParty: coordinator.pushPartyCreate,
                      onCreateEvent: openFirstEventCreate,
                      draftEventCard: state.draftEvents.isEmpty
                          ? null
                          : HomeDraftEventCard(
                              draft: state.draftEvents.first,
                              partyName: partyNameFor(
                                state.draftEvents.first.partyId,
                              ),
                              onResume: () => coordinator.pushEventCreate(
                                state.draftEvents.first.partyId,
                              ),
                            ),
                      onOpenGuide: coordinator.pushPartnerGuide,
                    ),
                  ] else ...[
                    HomeOverviewBlock(
                      totalPartyCount: state.totalPartyCount,
                      recruitingCount: state.recruitingEvents.length,
                      totalAttendees: state.totalAttendees,
                      onPartiesTap: () {
                        unawaited(const PartyListRoute().push<void>(context));
                      },
                      onEventsTap: coordinator.pushActiveEventList,
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
                            onCheckin: () {
                              unawaited(
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OngoingEventListPage(event: event),
                                  ),
                                ),
                              );
                            },
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
                      const HomeSectionHeader(title: '진행 임박'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.preparingEvents.map(
                        (event) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeUpcomingEventCard(
                            event: event,
                            onTap: () {
                              unawaited(
                                Navigator.of(context).push<void>(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        OngoingEventListPage(event: event),
                                  ),
                                ),
                              );
                            },
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
                    if (state.draftEvents.isNotEmpty) ...[
                      const SizedBox(height: MinglitSpacing.large),
                      const HomeSectionHeader(title: '작성 중'),
                      const SizedBox(height: MinglitSpacing.small),
                      ...state.draftEvents.map(
                        (draft) => Padding(
                          padding: const EdgeInsets.only(
                            bottom: MinglitSpacing.small,
                          ),
                          child: HomeDraftEventCard(
                            draft: draft,
                            partyName: partyNameFor(draft.partyId),
                            onResume: () =>
                                coordinator.pushEventCreate(draft.partyId),
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

class _BankAccountTodoCard extends StatelessWidget {
  const _BankAccountTodoCard({
    required this.verificationStatus,
    required this.onTap,
  });

  final String verificationStatus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = verificationStatus == bankVerificationStatusPending
        ? '계좌 확인 중'
        : '계좌 등록';
    final subtitle = verificationStatus == bankVerificationStatusFailed
        ? '계좌 정보를 다시 확인해주세요'
        : verificationStatus == bankVerificationStatusPending
        ? '운영 확인이 완료되면 사라져요'
        : '정산 받을 계좌를 등록해주세요';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: colorScheme.tertiary.withValues(
              alpha: MinglitOpacity.highlight,
            ),
            borderRadius: BorderRadius.circular(MinglitRadius.input),
          ),
          child: Icon(
            Icons.account_balance_wallet_outlined,
            color: colorScheme.tertiary,
            size: MinglitIconSize.small,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
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
    return ListView.separated(
      shrinkWrap: true,
      itemCount: parties.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final party = parties[index];
        return MinglitListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: party.title,
          onTap: () => Navigator.of(context).pop(party),
        );
      },
    );
  }
}
