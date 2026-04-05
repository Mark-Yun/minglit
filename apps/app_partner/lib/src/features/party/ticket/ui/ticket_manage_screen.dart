import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ticket_manage_screen.g.dart';

@riverpod
Future<List<Ticket>> partyTickets(Ref ref, String eventId) {
  return ref.read(ticketRepositoryProvider).getTicketsByEventId(eventId);
}

class TicketManageScreen extends ConsumerWidget {
  const TicketManageScreen({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ticketsAsync = ref.watch(partyTicketsProvider(eventId));

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '티켓 관리'),
      body: MinglitAsyncValueWidget<List<Ticket>>(
        value: ticketsAsync,
        data: (tickets) {
          if (tickets.isEmpty) {
            return const Center(child: Text('등록된 티켓이 없습니다.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: tickets.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              return _TicketManageCard(
                ticket: tickets[index],
                onUpdate: () => ref.invalidate(partyTicketsProvider(eventId)),
              );
            },
          );
        },
      ),
    );
  }
}

class _TicketManageCard extends ConsumerWidget {
  const _TicketManageCard({required this.ticket, required this.onUpdate});

  final Ticket ticket;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ticket.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              _buildStatusChip(context, ticket.status),
            ],
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            ticket.description ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Divider(height: MinglitSpacing.large),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatter.format(ticket.price)}원',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    '${ticket.soldCount} / ${ticket.quantity}매 판매',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              OutlinedButton(
                onPressed: () => _showEditSheet(context, ref),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(80, 36),
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.sm,
                  ),
                ),
                child: const Text('수정'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, String status) {
    Color color;
    String label;

    switch (status) {
      case 'on_sale':
        color = MinglitColors.primary;
        label = '판매중';
      case 'sold_out':
        color = MinglitColors.error;
        label = '매진';
      case 'hidden':
        color = Theme.of(context).colorScheme.outline;
        label = '숨김';
      default:
        color = Theme.of(context).colorScheme.outline;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context, WidgetRef ref) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _TicketEditSheet(ticket: ticket, onSaved: onUpdate),
      ),
    );
  }
}

class _TicketEditSheet extends ConsumerStatefulWidget {
  const _TicketEditSheet({required this.ticket, required this.onSaved});

  final Ticket ticket;
  final VoidCallback onSaved;

  @override
  ConsumerState<_TicketEditSheet> createState() => _TicketEditSheetState();
}

class _TicketEditSheetState extends ConsumerState<_TicketEditSheet> {
  late final TextEditingController _quantityController;
  late final TextEditingController _priceController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: widget.ticket.quantity.toString(),
    );
    _priceController = TextEditingController(
      text: widget.ticket.price.toString(),
    );
    _status = widget.ticket.status;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newQuantity = int.tryParse(_quantityController.text) ?? 0;
    final newPrice = int.tryParse(_priceController.text) ?? 0;

    final loading = ref.read(globalLoadingControllerProvider.notifier)..show();
    try {
      await ref
          .read(ticketRepositoryProvider)
          .updateTicket(
            widget.ticket.copyWith(
              quantity: newQuantity,
              price: newPrice,
              status: _status,
            ),
          );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
      if (mounted) context.showMinglitSuccess('티켓 정보가 수정되었습니다.');
    } on Exception catch (e, st) {
      if (mounted) handleMinglitError(context, e, st);
    } finally {
      loading.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: MinglitSpacing.medium,
        right: MinglitSpacing.medium,
        top: MinglitSpacing.medium,
        bottom:
            MediaQuery.of(context).viewInsets.bottom + MinglitSpacing.medium,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '티켓 수정',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _quantityController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '전체 수량',
                    helperText: '판매된 수량보다 적게 설정할 수 없습니다.',
                  ),
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: '가격 (원)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.large),
          const Text('판매 상태'),
          const SizedBox(height: MinglitSpacing.small),
          MinglitChipGroup(
            scrollable: false,
            padding: EdgeInsets.zero,
            children: [
              _buildStatusChoice('on_sale', '판매중'),
              _buildStatusChoice('sold_out', '매진'),
              _buildStatusChoice('hidden', '숨김'),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xlarge),
          ElevatedButton(onPressed: _save, child: const Text('저장하기')),
        ],
      ),
    );
  }

  Widget _buildStatusChoice(String value, String label) {
    final isSelected = _status == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _status = value);
      },
    );
  }
}
