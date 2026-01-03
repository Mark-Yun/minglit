import 'dart:async';

import 'package:app_partner/src/features/party/create/ticket_template_create_page.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/widgets/party_events_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_tickets_summary.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart' hide partyEventsProvider;

class PartyDetailOperationTab extends ConsumerWidget {
  const PartyDetailOperationTab({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(partyTicketsProvider(party.id));
    final eventsAsync = ref.watch(partyEventsProvider(party.id));
    final coordinator = ref.read(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);

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
            data: (tickets) => PartyTicketsSummary(
              tickets: tickets,
              entryGroups: party.entryGroups,
              maxCapacity: party.maxParticipants,
              showStats: false,
              onCreatePressed: () => _handleCreateTicket(context, ref),
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
            data: (events) => PartyEventsSummary(
              events: events,
              onEventTap: (event) =>
                  coordinator.goToEventDetail(party.id, event.id),
              onCreatePressed: () => coordinator.goToCreateEvent(party.id),
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

  Future<void> _handleCreateTicket(BuildContext context, WidgetRef ref) async {
    final newTicket = await Navigator.of(context).push<Ticket>(
      MaterialPageRoute(
        builder: (_) => TicketTemplateCreatePage(
          entryGroups: party.entryGroups,
        ),
      ),
    );

    if (newTicket != null && context.mounted) {
      final loading = ref.read(globalLoadingControllerProvider.notifier)
        ..show();
      try {
        final repo = ref.read(ticketRepositoryProvider);
        await repo.createTicket(
          newTicket.copyWith(partyId: party.id, eventId: null),
        );
        ref.invalidate(partyTicketsProvider(party.id));

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.partyDetail_message_ticketAdded),
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
  }
}
