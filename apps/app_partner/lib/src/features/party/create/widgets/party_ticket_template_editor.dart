import 'dart:async';

import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyTicketTemplateEditor extends StatelessWidget {
  const PartyTicketTemplateEditor({
    required this.ticketTemplates,
    required this.onAdd,
    required this.onRemove,
    super.key,
  });

  final List<EventTicket> ticketTemplates;
  final void Function(EventTicket) onAdd;
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
          onTap: () => unawaited(_showAddTicketDialog(context)),
        ),
      ],
    );
  }

  Future<void> _showAddTicketDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '0');
    final quantityController = TextEditingController(text: '20');
    String? selectedGender;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('기본 티켓 추가'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '티켓 이름'),
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    TextFormField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '가격',
                        suffixText: '원',
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '기본 수량',
                        suffixText: '매',
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    const Text('구매 가능 성별'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ChoiceChip(
                          label: const Text('전체'),
                          selected: selectedGender == null,
                          onSelected: (_) =>
                              setDialogState(() => selectedGender = null),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('남성'),
                          selected: selectedGender == 'male',
                          onSelected: (_) =>
                              setDialogState(() => selectedGender = 'male'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('여성'),
                          selected: selectedGender == 'female',
                          onSelected: (_) =>
                              setDialogState(() => selectedGender = 'female'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _handleAddTicket(
                      context,
                      nameController.text,
                      priceController.text,
                      quantityController.text,
                      selectedGender,
                    );
                  },
                  child: const Text('추가'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _handleAddTicket(
    BuildContext context,
    String name,
    String priceStr,
    String qtyStr,
    String? gender,
  ) {
    final price = int.tryParse(priceStr) ?? 0;
    final quantity = int.tryParse(qtyStr) ?? 0;

    final ticket = EventTicket(
      id: '', // Temporary
      name: name,
      price: price,
      quantity: quantity,
      conditions: {
        'gender': gender,
      }..removeWhere((k, v) => v == null),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    onAdd(ticket);
    Navigator.pop(context);
  }
}
