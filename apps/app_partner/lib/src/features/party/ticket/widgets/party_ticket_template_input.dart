import 'dart:async';

import 'package:app_partner/src/features/party/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/ticket/ticket_template_create_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyTicketTemplateInput extends StatelessWidget {
  const PartyTicketTemplateInput({
    required this.ticketTemplates,
    required this.entryGroups,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdate,
    this.maxParticipants,
    super.key,
  });

  final List<TicketTemplate> ticketTemplates;
  final void Function(TicketTemplate) onAdd;
  final void Function(int) onRemove;
  final void Function(int, TicketTemplate) onUpdate;
  final List<PartyEntryGroup> entryGroups;
  final int? maxParticipants;

  @override
  Widget build(BuildContext context) {
    // Calculate total issued tickets
    final totalIssued = ticketTemplates.fold(0, (sum, t) => sum + t.quantity);

    return Column(
      children: [
        // 0. Status Header
        if (ticketTemplates.isNotEmpty && maxParticipants != null)
          TicketStatusHeader(
            totalIssued: totalIssued,
            maxParticipants: maxParticipants,
          ),

        // 1. Existing Templates List
        if (ticketTemplates.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ticketTemplates.length,
            itemBuilder: (context, index) {
              final template = ticketTemplates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
                child: TicketListItem(
                  ticket: Ticket.createFromTemplate(template),
                  entryGroups: entryGroups,
                  showStats: false,
                  onTap: () =>
                      unawaited(_navigateToEditPage(context, index, template)),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => onRemove(index),
                  ),
                ),
              );
            },
          ),

        // 2. Add Button
        AddActionCard(
          title: '기본 티켓 추가하기',
          subtitle: '이벤트 생성 시 자동으로 채워질 티켓입니다.',
          onTap: () => unawaited(_navigateToAddPage(context)),
        ),
      ],
    );
  }

  Future<void> _navigateToAddPage(BuildContext context) async {
    final template = await Navigator.of(context).push<TicketTemplate>(
      MaterialPageRoute(
        builder: (_) => TicketTemplateCreatePage(entryGroups: entryGroups),
      ),
    );

    if (template != null) {
      onAdd(template);
    }
  }

  Future<void> _navigateToEditPage(
    BuildContext context,
    int index,
    TicketTemplate template,
  ) async {
    final updatedTemplate = await Navigator.of(context).push<TicketTemplate>(
      MaterialPageRoute(
        builder: (_) => TicketTemplateCreatePage(
          entryGroups: entryGroups,
          initialTicket: template,
        ),
      ),
    );

    if (updatedTemplate != null) {
      onUpdate(index, updatedTemplate);
    }
  }
}
