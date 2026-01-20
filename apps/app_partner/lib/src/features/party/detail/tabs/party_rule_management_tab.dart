import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/ticket/ticket_template_create_page.dart';
import 'package:app_partner/src/features/party/ticket/widgets/party_tickets_summary.dart';
import 'package:app_partner/src/features/party/widgets/party_entrance_condition_summary.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/ui/widgets/common/minglit_editable_section.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyRuleManagementTab extends ConsumerWidget {
  const PartyRuleManagementTab({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(partyTicketsProvider(party.id));
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Entrance Conditions (Top)
          MinglitEditableSection(
            title: context.l10n.partyDetail_section_entranceCondition,
            onTap: () {
              // Navigate to entry group edit screen or show message
              // Currently read-only in DetailInfoTab, so keeping it similar
              // for now but ideally this should be editable here.
              _showEntranceConditionsEdit(context, ref, party);
            },
            child: PartyEntranceConditionSummary(
              entryGroups: party.entryGroups ?? [],
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // 2. Tickets (Bottom)
          Text(
            context.l10n.partyDetail_section_tickets,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          MinglitAsyncValueWidget(
            value: ticketsAsync,
            data: (templates) => PartyTicketsSummary(
              tickets: templates
                  .map((t) => Ticket.createFromTemplate(t, id: t.id))
                  .toList(),
              entryGroups: party.entryGroups ?? [],
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
            error: (e, s) =>
                Text(context.l10n.partyDetail_error_ticketLoad(e.toString())),
          ),
        ],
      ),
    );
  }

  void _showEntranceConditionsEdit(
    BuildContext context,
    WidgetRef ref,
    Party party,
  ) {
    // Placeholder for future implementation of Entry Group editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('입장 조건 수정 기능은 준비 중입니다.')),
    );
  }

  Future<void> _handleCreateTicket(BuildContext context, WidgetRef ref) async {
    final newTemplate = await Navigator.of(context).push<TicketTemplate>(
      MaterialPageRoute(
        builder: (_) => TicketTemplateCreatePage(
          entryGroups: party.entryGroups ?? [],
        ),
      ),
    );

    if (newTemplate != null && context.mounted) {
      final loading = ref.read(globalLoadingControllerProvider.notifier)
        ..show();
      try {
        final repo = ref.read(ticketRepositoryProvider);
        await repo.createTicketTemplate(
          newTemplate.copyWith(partyId: party.id),
        );
        ref.invalidate(partyTicketsProvider(party.id));

        if (context.mounted) {
          context.showMinglitSuccess(
            context.l10n.partyDetail_message_ticketAdded,
          );
        }
      } on Exception catch (e, st) {
        if (context.mounted) {
          handleMinglitError(context, e, st);
        }
      } finally {
        loading.hide();
      }
    }
  }
}
