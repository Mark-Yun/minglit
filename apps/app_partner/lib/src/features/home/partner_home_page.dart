import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/features/home/partner_home_coordinator.dart';
import 'package:app_partner/src/features/home/widgets/active_party_summary_scroll.dart';
import 'package:app_partner/src/features/home/widgets/closing_soon_events_card.dart';
import 'package:app_partner/src/features/home/widgets/location_guide_banner.dart';
import 'package:app_partner/src/features/home/widgets/pending_applicants_badge_card.dart';
import 'package:app_partner/src/features/home/widgets/upcoming_events_card.dart';
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
    final coordinator = ref.read(partnerHomeCoordinatorProvider);

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
                onPressed: coordinator.pushNotificationCenter,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final parties = state.activeParties;
          if (parties.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('먼저 파티를 생성해주세요')),
            );
            return;
          }
          final selected = await showModalBottomSheet<Party>(
            context: context,
            builder: (context) => _PartySelectionSheet(parties: parties),
          );
          if (selected != null && context.mounted) {
            EventCreateRoute(partyId: selected.id).push<void>(context);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('이벤트 생성'),
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
                // 1. Pending Applicants
                PendingApplicantsBadgeCard(
                  count: state.pendingReviewCount,
                  onTap: coordinator.pushApplicationList,
                ),
                const SizedBox(height: MinglitSpacing.large),

                // 2. Upcoming Events
                UpcomingEventsCard(
                  events: state.upcomingEvents,
                  onEventTap: (event) {
                    EventDetailRoute(
                      partyId: event.partyId,
                      eventId: event.id,
                    ).push<void>(context);
                  },
                ),
                const SizedBox(height: MinglitSpacing.large),

                // 3. Active Party Summary
                ActivePartySummaryScroll(
                  parties: state.activeParties,
                  onPartyTap: (party) {
                    PartyDetailRoute(partyId: party.id).push<void>(context);
                  },
                ),
                const SizedBox(height: MinglitSpacing.large),

                // 4. Closing Soon Events
                ClosingSoonEventsCard(
                  events: state.closingSoonEvents,
                  onEventTap: (event) {
                    EventDetailRoute(
                      partyId: event.partyId,
                      eventId: event.id,
                    ).push<void>(context);
                  },
                ),
                const SizedBox(height: MinglitSpacing.large),

                // 5. Location Guide Banner
                LocationGuideBanner(
                  onTap: () {
                    const LocationGuideRoute().go(context);
                  },
                ),

                const SizedBox(height: 100), // Bottom padding for FAB/Nav
              ],
            ),
          ),
        ),
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
