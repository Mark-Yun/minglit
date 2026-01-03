import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/create/ticket_template_create_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/widgets/event_list_item.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_basic_condition_section.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_info_chip.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_location_section.dart';
import 'package:app_partner/src/features/party/entry_group/entry_group_editor_screen.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: partyAsync.when(
          data: (party) => NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
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
                        unawaited(
                          coordinator.deactivateParty(party.id, context),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            const Icon(Icons.edit, size: MinglitIconSize.small),
                            const SizedBox(width: MinglitSpacing.small),
                            Text(context.l10n.partyDetail_menu_edit),
                          ],
                        ),
                      ),
                      if (party.status == 'closed')
                        PopupMenuItem(
                          value: 'activate',
                          child: Row(
                            children: [
                              const Icon(
                                Icons.play_arrow_outlined,
                                size: MinglitIconSize.small,
                              ),
                              const SizedBox(width: MinglitSpacing.small),
                              Text(context.l10n.partyDetail_menu_activate),
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
                                context.l10n.partyDetail_menu_deactivate,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              // 2. TabBar (Wizard Step style integration)
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TabBar(
                        indicatorWeight: 3,
                        tabs: [
                          Tab(text: context.l10n.partyDetail_tab_operation),
                          Tab(text: context.l10n.partyDetail_tab_info),
                        ],
                      ),
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            body: TabBarView(
              children: [
                // Tab 1: 회차 및 티켓 (Operation)
                _buildOperationTab(
                  context,
                  ref,
                  party,
                  ticketsAsync,
                  eventsAsync,
                ),
                // Tab 2: 파티 정보 (Info)
                _buildInfoTab(context, ref, party),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Scaffold(
            appBar: MinglitTheme.simpleAppBar(title: ''),
            body: Center(
              child: Text(
                context.l10n.partyDetail_error_partyLoad(e.toString()),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOperationTab(
    BuildContext context,
    WidgetRef ref,
    Party party,
    AsyncValue<List<Ticket>> ticketsAsync,
    AsyncValue<List<Event>> eventsAsync,
  ) {
    final theme = Theme.of(context);
    final coordinator = ref.read(partyDetailCoordinatorProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Tickets Section
          Text(
            context.l10n.partyDetail_section_tickets,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          ticketsAsync.when(
            data: (tickets) => TicketListView(
              tickets: tickets,
              entryGroups: party.entryGroups,
              maxParticipants: party.maxParticipants,
              showStats: false,
              onCreatePressed: () async {
                final newTicket = await Navigator.of(context).push<Ticket>(
                  MaterialPageRoute(
                    builder: (_) => TicketTemplateCreatePage(
                      entryGroups: party.entryGroups,
                    ),
                  ),
                );

                if (newTicket != null && context.mounted) {
                  final loading = ref.read(
                    globalLoadingControllerProvider.notifier,
                  )..show();
                  try {
                    final repo = ref.read(ticketRepositoryProvider);
                    await repo.createTicket(
                      newTicket.copyWith(partyId: party.id, eventId: null),
                    );
                    ref.invalidate(partyTicketsProvider(party.id));

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.l10n.partyDetail_message_ticketAdded,
                          ),
                        ),
                      );
                    }
                  } on Exception catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.l10n.common_error_system),
                        ),
                      );
                    }
                  } finally {
                    loading.hide();
                  }
                }
              },
              onTicketTap: (ticket) {
                unawaited(
                  PartyTicketEditRoute(
                    partyId: party.id,
                    ticketId: ticket.id,
                  ).push<void>(context),
                );
              },
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(
              context.l10n.partyDetail_error_ticketLoad(e.toString()),
            ),
          ),

          const SizedBox(height: MinglitSpacing.xlarge),

          // 2. Events Section
          Text(
            context.l10n.partyDetail_section_events,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          eventsAsync.when(
            data: (events) => Column(
              children: [
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: MinglitSpacing.small,
                    ),
                    child: EventListItem(
                      event: event,
                      onTap: () =>
                          coordinator.goToEventDetail(party.id, event.id),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: MinglitSpacing.xxsmall),
                  child: AddActionCard(
                    title: context.l10n.partyDetail_button_createEvent,
                    subtitle: context.l10n.partyDetail_subtitle_createEvent,
                    onTap: () => coordinator.goToCreateEvent(party.id),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Text(
              context.l10n.partyDetail_error_eventLoad(e.toString()),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, WidgetRef ref, Party party) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PartyInfoChip(
                icon: Icons.people_outline,
                label:
                    '${party.minConfirmedCount}'
                    '~${party.maxParticipants}명',
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partyDetail_section_entranceCondition,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          PartyBasicConditionSection(
            party: party,
            onGroupTap: (PartyEntryGroup group) async {
              final coordinator = ref.read(partyDetailCoordinatorProvider);
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => EntryGroupEditorScreen(
                    initialGroup: group,
                    onSaved: (PartyEntryGroup updatedGroup) {
                      unawaited(
                        coordinator.updatePartyEntryGroup(
                          party.id,
                          updatedGroup,
                          context,
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partyDetail_section_location,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          PartyLocationSection(
            locationId: party.locationId,
            partyId: party.id,
          ),
          const SizedBox(height: MinglitSpacing.large),
          Text(
            context.l10n.partyDetail_section_locationDetail,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          PartyLocationDetailSection(locationId: party.locationId),
          const SizedBox(height: MinglitSpacing.xlarge),
        ],
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this.child);

  final Widget child;

  @override
  double get minExtent => 50; // Increased height to accommodate divider
  @override
  double get maxExtent => 50;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
