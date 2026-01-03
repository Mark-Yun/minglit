import 'package:app_partner/src/features/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/ticket/controller/ticket_controller.dart';
import 'package:app_partner/src/features/ticket/widgets/ticket_form.dart';
import 'package:app_partner/src/utils/error_handler.dart';
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
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final ticketState = ref.watch(ticketControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.ticket_title_create)),
      body: partyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Text(
            context.l10n.partyDetail_error_partyLoad(e.toString()),
          ),
        ),
        data: (Party party) {
          final entryGroups = party.entryGroups;
          final event = eventAsync.asData?.value;

          // Calculate initial quantity
          int? initialQuantity;
          if (event != null && entryGroups.isNotEmpty) {
            initialQuantity =
                (event.maxParticipants / entryGroups.length).floor();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: TicketForm(
              entryGroups: entryGroups,
              initialQuantity: initialQuantity,
              submitButtonLabel: context.l10n.ticket_button_create,
              isLoading: ticketState.isLoading,
              onSaved: ({
                required String name,
                required int price,
                required int quantity,
                required List<String> targetEntryGroupIds,
              }) async {
                await ref.read(ticketControllerProvider.notifier).createTicket(
                      eventId: eventId,
                      name: name,
                      price: price,
                      quantity: quantity,
                      targetEntryGroupIds: targetEntryGroupIds,
                    );

                final updatedState = ref.read(ticketControllerProvider);
                if (!updatedState.hasError && context.mounted) {
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.l10n.ticket_message_created)),
                  );
                  ref.invalidate(eventTicketsProvider(eventId));
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
      ),
    );
  }
}