import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/widgets/add_event_card.dart';
import 'package:app_partner/src/features/party/detail/widgets/event_list_item.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart' hide partyEventsProvider;

class PartyDetailPage extends ConsumerWidget {
  const PartyDetailPage({required this.partyId, super.key});

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final eventsAsync = ref.watch(partyEventsProvider(partyId));
    final ticketsAsync = ref.watch(partyTicketsProvider(partyId));
    final coordinator = ref.watch(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: partyAsync.when(
        data: (party) => CustomScrollView(
          slivers: [
            // 1. Header with Image
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  party.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black45, blurRadius: 8),
                    ],
                  ),
                ),
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (party.imageUrl != null)
                      Image.network(party.imageUrl!, fit: BoxFit.cover)
                    else
                      Container(color: colorScheme.primaryContainer),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onSelected: (value) {
                    if (value == 'edit') {
                      coordinator.goToEditParty(party.id);
                    } else if (value == 'activate') {
                      unawaited(coordinator.activateParty(party.id, context));
                    } else if (value == 'deactivate') {
                      unawaited(coordinator.deactivateParty(party.id, context));
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: MinglitIconSize.small),
                          SizedBox(width: MinglitSpacing.small),
                          Text('파티 정보 수정'),
                        ],
                      ),
                    ),
                    if (party.status == 'closed')
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.play_arrow_outlined,
                              size: MinglitIconSize.small,
                            ),
                            SizedBox(width: MinglitSpacing.small),
                            Text('파티 다시 활성화'),
                          ],
                        ),
                      ),
                    if (party.status == 'active')
                      PopupMenuItem(
                        value: 'deactivate',
                        child: Row(
                          children: [
                            Icon(
                              Icons.archive_outlined,
                              size: MinglitIconSize.small,
                              color: colorScheme.error,
                            ),
                            const SizedBox(width: MinglitSpacing.small),
                            Text(
                              '파티 비활성화 (보관)',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),

            // 2. Party Info Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _InfoChip(
                          icon: Icons.people_outline,
                          label:
                              '${party.minConfirmedCount}'
                              '~${party.maxParticipants}명',
                        ),
                        const SizedBox(width: MinglitSpacing.small),
                        _InfoChip(
                          icon: Icons.verified_user_outlined,
                          label:
                              '${party.requiredVerificationIds.length}개 인증 필수',
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      '개설된 회차 (이벤트)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                  ],
                ),
              ),
            ),

            // 3. Events List
            eventsAsync.when(
              data: (events) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < events.length) {
                        final event = events[index];
                        return EventListItem(
                          event: event,
                          onTap: () => coordinator.goToEventDetail(
                            party.id,
                            event.id,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(
                          top: MinglitSpacing.xxsmall,
                        ),
                        child: AddEventCard(
                          onTap: () => coordinator.goToCreateEvent(party.id),
                        ),
                      );
                    },
                    childCount: events.length + 1,
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('이벤트 로드 실패: $e')),
              ),
            ),

            // 4. Registered Tickets Summary
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  MinglitSpacing.medium,
                  MinglitSpacing.xlarge,
                  MinglitSpacing.medium,
                  MinglitSpacing.small,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '등록된 티켓 현황',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        if (eventsAsync.value?.isEmpty ?? true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('티켓을 만들기 전, 먼저 회차(이벤트)를 개설해주세요.'),
                            ),
                          );
                          return;
                        }
                        final firstEvent = eventsAsync.value!.first;
                        coordinator.goToCreateTicket(partyId, firstEvent.id);
                      },
                      icon: const Icon(
                        Icons.add,
                        size: MinglitIconSize.small,
                      ),
                      label: const Text('티켓 생성'),
                    ),
                  ],
                ),
              ),
            ),

            ticketsAsync.when(
              data: (tickets) => SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                sliver: SliverToBoxAdapter(
                  child: TicketListView(
                    tickets: tickets,
                    onCreatePressed: (eventsAsync.value?.isNotEmpty ?? false)
                        ? () {
                            final firstEvent = eventsAsync.value!.first;
                            coordinator.goToCreateTicket(
                              partyId,
                              firstEvent.id,
                            );
                          }
                        : null,
                    onTicketTap: (ticket) {
                      // Navigate to appropriate detail/edit if needed
                    },
                  ),
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, s) => SliverToBoxAdapter(
                child: Center(child: Text('티켓 로드 실패: $e')),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: MinglitSpacing.xlarge),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Scaffold(
          appBar: AppBar(),
          body: Center(child: Text('파티 로드 실패: $e')),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: MinglitIconSize.xsmall,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
