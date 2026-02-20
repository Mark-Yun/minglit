part of 'ticket_selection_sheet.dart';

extension _TicketSelectionWidgets on _TicketSelectionSheetState {
  Widget buildTicketOption(
    Ticket ticket, {
    required bool isLocked,
    required bool isRecommended,
    required String? ineligibleReason,
  }) {
    final isSelected = _selectedTicketId == ticket.id;
    final theme = Theme.of(context);
    final formatter = NumberFormat('#,###');
    final nameColor = isLocked
        ? theme.colorScheme.onSurfaceVariant
        : isSelected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface;
    final priceColor = isLocked ? theme.colorScheme.onSurfaceVariant : null;

    return GestureDetector(
      onTap: isLocked ? null : () => _selectTicket(ticket.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
        child: Stack(
          children: [
            Opacity(
              opacity: isLocked ? 0.5 : 1,
              child: Container(
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
                              color: nameColor,
                            ),
                          ),
                          if (ticket.description != null)
                            Text(
                              ticket.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          if (isLocked && ineligibleReason != null)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: MinglitSpacing.xsmall,
                              ),
                              child: Text(
                                ineligibleReason,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${formatter.format(ticket.price)}원',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLocked)
              Positioned(
                top: MinglitSpacing.small,
                right: MinglitSpacing.small,
                child: _buildBalanceBadge(theme),
              ),
            if (!isLocked && isRecommended)
              Positioned(
                top: MinglitSpacing.small,
                right: MinglitSpacing.small,
                child: _buildRecommendedBadge(theme),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Text(
        '성비 조절 중',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRecommendedBadge(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: theme.colorScheme.primary),
      ),
      child: Text(
        '추천',
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget buildQuantityStepper() {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        children: [
          const IconButton(
            onPressed: null,
            icon: Icon(Icons.remove, size: MinglitIconSize.xsmall),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          Text(
            '$_quantity',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            onPressed: () =>
                context.showMinglitInfo('친구와 함께 참가하기 기능은 준비 중입니다.'),
            icon: const Icon(Icons.add, size: MinglitIconSize.xsmall),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  String calculateTotal() {
    if (_selectedTicketId == null) return '0원';
    final ticket = widget.event.tickets!.firstWhere(
      (t) => t.id == _selectedTicketId,
    );
    return '${NumberFormat('#,###').format(ticket.price * _quantity)}원';
  }
}
