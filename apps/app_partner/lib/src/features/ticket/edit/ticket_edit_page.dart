import 'package:app_partner/src/features/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/ticket/controller/ticket_controller.dart';
import 'package:app_partner/src/features/ticket/widgets/ticket_form.dart';
import 'package:app_partner/src/utils/error_handler.dart';
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
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final ticketAsync = ref.watch(ticketDetailProvider(ticketId));
    final ticketState = ref.watch(ticketControllerProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: context.l10n.ticket_title_edit),
      body: ticketAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, StackTrace s) => Center(
          child: Text(
            context.l10n.partyDetail_error_ticketLoad(
              e.toString(),
            ),
          ),
        ),
        data: (Ticket ticket) {
          return partyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (Object e, StackTrace s) => Center(
              child: Text(
                context.l10n.partyDetail_error_partyLoad(
                  e.toString(),
                ),
              ),
            ),
            data: (Party party) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: TicketForm(
                  initialTicket: ticket,
                  entryGroups: party.entryGroups,
                  submitButtonLabel: context.l10n.ticket_button_edit,
                  isLoading: ticketState.isLoading,
                  onSaved:
                      ({
                        required String name,
                        required int price,
                        required int quantity,
                        required List<String> targetEntryGroupIds,
                      }) async {
                        await ref
                            .read(ticketControllerProvider.notifier)
                            .updateTicket(
                              ticket: ticket,
                              name: name,
                              price: price,
                              quantity: quantity,
                              targetEntryGroupIds: targetEntryGroupIds,
                            );

                        final updatedState = ref.read(ticketControllerProvider);
                        if (!updatedState.hasError && context.mounted) {
                          context.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.ticket_message_updated,
                              ),
                            ),
                          );
                          ref.invalidate(ticketDetailProvider(ticketId));
                          if (eventId.isNotEmpty) {
                            ref.invalidate(eventTicketsProvider(eventId));
                          } else {
                            ref.invalidate(partyTicketsProvider(partyId));
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
