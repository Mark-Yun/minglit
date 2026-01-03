import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/ticket/widgets/ticket_form.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketTemplateCreatePage extends ConsumerWidget {
  const TicketTemplateCreatePage({
    required this.entryGroups,
    this.initialTicket,
    super.key,
  });

  final List<PartyEntryGroup> entryGroups;
  final Ticket? initialTicket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizardState = ref.watch(partyCreateWizardControllerProvider);

    // Calculate other tickets' total quantity in the wizard state
    final otherTicketsQuantity = wizardState.tickets
        .where((t) => initialTicket == null || t.id != initialTicket!.id)
        .fold(0, (sum, t) => sum + t.quantity);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          initialTicket == null ? '기본 티켓 추가' : '티켓 수정',
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: TicketForm(
          entryGroups: entryGroups,
          initialTicket: initialTicket,
          maxCapacity: wizardState.maxParticipants,
          otherTicketsQuantity: otherTicketsQuantity,
          submitButtonLabel: initialTicket == null ? '추가하기' : '수정 완료',
          onSaved:
              ({
                required String name,
                required int price,
                required int quantity,
                required List<String> targetEntryGroupIds,
              }) {
                final ticket =
                    (initialTicket ??
                            Ticket(
                              id: '', // Temporary ID
                              name: '',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                            ))
                        .copyWith(
                          name: name,
                          price: price,
                          quantity: quantity,
                          targetEntryGroupIds: targetEntryGroupIds,
                          updatedAt: DateTime.now(),
                        );

                Navigator.of(context).pop(ticket);
              },
        ),
      ),
    );
  }
}
