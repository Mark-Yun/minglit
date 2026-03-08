import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/ticket/logic/ticket_controller.dart';
import 'package:app_partner/src/features/ticket/widgets/ticket_form.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketCreatePage extends ConsumerWidget {
  const TicketCreatePage({
    required this.partyId,
    required this.eventId,
    super.key,
  });

  final String partyId;
  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));

    Future<void> handleSave({
      required String name,
      required int price,
      required int quantity,
      required List<String> targetEntryGroupIds,
    }) async {
      await ref
          .read(ticketControllerProvider.notifier)
          .createTicket(
            eventId: eventId,
            name: name,
            price: price,
            quantity: quantity,
            targetEntryGroupIds: targetEntryGroupIds,
          );

      final state = ref.read(ticketControllerProvider);
      if (!state.hasError && context.mounted) {
        context
          ..pop()
          ..showMinglitSuccess(context.l10n.ticket_message_created);
        if (eventId.isNotEmpty) {
          ref.invalidate(eventTicketsProvider(eventId));
        } else {
          ref.invalidate(partyTicketsProvider(partyId));
        }
      } else if (state.hasError && context.mounted) {
        handleMinglitError(context, state.error!, state.stackTrace);
      }
    }

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.ticket_title_create,
      ),
      body: MinglitAsyncValueWidget(
        value: partyAsync,
        data: (party) => SingleChildScrollView(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: TicketForm(
            entryGroups: party.entryGroups ?? [],
            submitButtonLabel: context.l10n.ticket_button_create,
            onSaved: handleSave,
          ),
        ),
      ),
    );
  }
}
