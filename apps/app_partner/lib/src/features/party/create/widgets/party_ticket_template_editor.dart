import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/features/party/create/ticket_template_create_page.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyTicketTemplateEditor extends StatelessWidget {
  const PartyTicketTemplateEditor({
    required this.ticketTemplates,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<Ticket> ticketTemplates;
  final void Function(Ticket) onAdd;
  final void Function(int) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 1. Existing Templates List
        if (ticketTemplates.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: ticketTemplates.length,
            itemBuilder: (context, index) {
              final ticket = ticketTemplates[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
                child: TicketListItem(
                  ticket: ticket,
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
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
    final ticket = await Navigator.of(context).push<Ticket>(
      MaterialPageRoute(builder: (_) => const TicketTemplateCreatePage()),
    );

    if (ticket != null) {
      onAdd(ticket);
    }
  }
}
