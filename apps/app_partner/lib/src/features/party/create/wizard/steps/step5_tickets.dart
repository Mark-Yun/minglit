import 'package:app_partner/src/features/party/create/widgets/party_ticket_template_editor.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step5Tickets extends ConsumerWidget {
  const Step5Tickets({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.partyCreate_title_tickets,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            context.l10n.partyCreate_desc_tickets,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: MinglitSpacing.large),
          PartyTicketTemplateEditor(
            ticketTemplates: state.tickets,
            onAdd: notifier.addTicket,
            onRemove: notifier.removeTicket,
          ),
        ],
      ),
    );
  }
}
