import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class TicketSelectionSheet extends ConsumerStatefulWidget {
  const TicketSelectionSheet({required this.event, super.key});

  final Event event;

  @override
  ConsumerState<TicketSelectionSheet> createState() =>
      _TicketSelectionSheetState();
}

class _TicketSelectionSheetState extends ConsumerState<TicketSelectionSheet> {
  String? _selectedTicketId;
  int _quantity = 1;

  void _onNext() {
    if (_selectedTicketId == null) return;

    // Close sheet first
    Navigator.pop(context);

    // Navigate to Application Wizard via Coordinator
    ref
        .read(eventCoordinatorProvider)
        .goToApplicationWizard(
          context,
          widget.event.id,
          ticketId: _selectedTicketId,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tickets = widget.event.tickets ?? [];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '티켓 선택',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          if (tickets.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('구매 가능한 티켓이 없습니다.'),
            )
          else
            ...tickets.map(_buildTicketOption),
          const SizedBox(height: 24),

          // Quantity (Only if ticket selected)
          if (_selectedTicketId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '수량',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                _buildQuantityStepper(),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '총 결제 금액',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  _calculateTotal(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedTicketId == null ? null : _onNext,
              child: const Text('다음'),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewPadding.bottom),
        ],
      ),
    );
  }

  Widget _buildTicketOption(Ticket ticket) {
    final isSelected = _selectedTicketId == ticket.id;
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTicketId = ticket.id;
          _quantity = 1; // Reset quantity on change
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : Colors.white,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : Colors.black,
                    ),
                  ),
                  if (ticket.description != null)
                    Text(
                      ticket.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${formatter.format(ticket.price)}원',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '$_quantity',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String _calculateTotal() {
    if (_selectedTicketId == null) return '0원';
    final ticket = widget.event.tickets!.firstWhere(
      (t) => t.id == _selectedTicketId,
    );
    return '${NumberFormat('#,###').format(ticket.price * _quantity)}원';
  }
}
