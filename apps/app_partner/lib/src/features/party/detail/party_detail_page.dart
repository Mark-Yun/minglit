import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/create/ticket_template_create_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/detail/widgets/event_list_item.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_basic_condition_section.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_info_chip.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_location_section.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_verification_section.dart';
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

            // 2. Party Info Summary
            SliverToBoxAdapter(
              child: Padding(
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
                    PartyBasicConditionSection(party: party),
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      context.l10n.partyDetail_section_verification,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    PartyVerificationSection(partyId: party.id),
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
                    const SizedBox(height: MinglitSpacing.large),
                    Text(
                      context.l10n.partyDetail_section_events,
                      style: theme.textTheme.titleMedium,
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
                        child: AddActionCard(
                          title: context.l10n.partyDetail_button_createEvent,
                          subtitle:
                              context.l10n.partyDetail_subtitle_createEvent,
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
                child: Center(
                  child: Text(
                    context.l10n.partyDetail_error_eventLoad(e.toString()),
                  ),
                ),
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
                child: Text(
                  context.l10n.partyDetail_section_tickets,
                  style: theme.textTheme.titleMedium,
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
                    onCreatePressed: () async {
                      final newTicket = await Navigator.of(context)
                          .push<Ticket>(
                            MaterialPageRoute(
                              builder: (_) => const TicketTemplateCreatePage(),
                            ),
                          );

                      if (newTicket != null) {
                        final loading = ref.read(
                          globalLoadingControllerProvider.notifier,
                        )..show();
                        try {
                          final repo = ref.read(ticketRepositoryProvider);
                          await repo.createTicket(
                            newTicket.copyWith(partyId: partyId, eventId: null),
                          );
                          ref.invalidate(partyTicketsProvider(partyId));

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
                                content: Text(
                                  context.l10n.common_error_system,
                                ),
                              ),
                            );
                          }
                        } finally {
                          loading.hide();
                        }
                      }
                    },
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
                child: Center(
                  child: Text(
                    context.l10n.partyDetail_error_ticketLoad(e.toString()),
                  ),
                ),
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
          body: Center(
            child: Text(context.l10n.partyDetail_error_partyLoad(e.toString())),
          ),
        ),
      ),
    );
  }
}
