import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/ticket/logic/ticket_controller.dart';
import 'package:app_partner/src/features/ticket/widgets/ticket_form.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketEditPage extends ConsumerWidget {
  const TicketEditPage({
    required this.ticketId,
    required this.partyId,
    required this.eventId,
    super.key,
  });

  final String ticketId;
  final String partyId;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTemplate = eventId.isEmpty;
    final partyAsync = ref.watch(partyDetailProvider(partyId));

    // Dynamic AsyncValue based on mode
    final ticketAsync = isTemplate
        ? ref.watch(ticketTemplateDetailProvider(ticketId)).whenData(
              (template) =>
                  Ticket.createFromTemplate(template, id: template.id),
            )
        : ref.watch(ticketDetailProvider(ticketId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: context.l10n.ticket_title_edit),
      body: MinglitAsyncValueWidget(
        value: ticketAsync,
        error: (e, s) => Center(
          child: Text(
            context.l10n.partyDetail_error_ticketLoad(e.toString()),
          ),
        ),
        data: (ticket) {
          return MinglitAsyncValueWidget(
            value: partyAsync,
            error: (e, s) => Center(
              child: Text(
                context.l10n.partyDetail_error_partyLoad(e.toString()),
              ),
            ),
            data: (party) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: TicketForm(
                  initialTicket: ticket,
                  entryGroups: party.entryGroups ?? [],
                  submitButtonLabel: context.l10n.ticket_button_edit,
                  onSaved: ({
                    required name,
                    required price,
                    required quantity,
                    required targetEntryGroupIds,
                  }) async {
                    if (isTemplate) {
                      // Update Template
                      final template = ref
                          .read(ticketTemplateDetailProvider(ticketId))
                          .value!;

                      await ref
                          .read(ticketControllerProvider.notifier)
                          .updateTicketTemplate(
                            template: template,
                            name: name,
                            price: price,
                            quantity: quantity,
                            targetEntryGroupIds: targetEntryGroupIds,
                          );
                    } else {
                      // Update Ticket Instance
                      await ref
                          .read(ticketControllerProvider.notifier)
                          .updateTicket(
                            ticket: ticket,
                            name: name,
                            price: price,
                            quantity: quantity,
                            targetEntryGroupIds: targetEntryGroupIds,
                          );
                    }

                    final updatedState = ref.read(ticketControllerProvider);
                    if (!updatedState.hasError && context.mounted) {
                      context
                        ..pop()
                        ..showMinglitSuccess(
                          context.l10n.ticket_message_updated,
                        );

                      if (isTemplate) {
                        ref
                          ..invalidate(
                            ticketTemplateDetailProvider(ticketId),
                          )
                          ..invalidate(partyTicketsProvider(partyId));
                      } else {
                        ref
                          ..invalidate(ticketDetailProvider(ticketId))
                          ..invalidate(eventTicketsProvider(eventId));
                      }
                    } else if (updatedState.hasError && context.mounted) {
                      handleMinglitError(
                        context,
                        updatedState.error!,
                        updatedState.stackTrace,
                      );
                    }
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
