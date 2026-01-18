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
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(MinglitRadius.card),
        ),
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
          const SizedBox(height: MinglitSpacing.medium),
          if (tickets.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.large,
              ),
              child: Text(
                '구매 가능한 티켓이 없습니다.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ...tickets.map(_buildTicketOption),
          const SizedBox(height: MinglitSpacing.large),

          // Quantity (Only if ticket selected)
          if (_selectedTicketId != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '수량',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildQuantityStepper(),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
            const Divider(),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 결제 금액',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _calculateTotal(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],

          SizedBox(
            width: double.infinity,
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
        margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(MinglitRadius.input),
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.05)
              : theme.colorScheme.surface,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (ticket.description != null)
                    Text(
                      ticket.description!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              '${formatter.format(ticket.price)}원',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityStepper() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
            icon: const Icon(Icons.remove, size: MinglitIconSize.xsmall),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '$_quantity',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () => setState(() => _quantity++),
            icon: const Icon(Icons.add, size: MinglitIconSize.xsmall),
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
