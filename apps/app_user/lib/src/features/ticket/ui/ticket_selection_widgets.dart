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
                      ? theme.colorScheme.primary.withValues(
                          alpha: MinglitOpacity.tintFill,
                        )
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

  // Fix #180: tickets null 및 firstWhere 매치 실패 시 crash 방지
  String calculateTotal() {
    if (_selectedTicketId == null) return '0원';
    final tickets = widget.event.tickets;
    if (tickets == null) return '0원';
    final ticket = tickets.where((t) => t.id == _selectedTicketId).firstOrNull;
    if (ticket == null) return '0원';
    return '${NumberFormat('#,###').format(ticket.price * _quantity)}원';
  }

  Widget buildLoadingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.large),
      child: Text('추천 티켓을 확인 중입니다.', style: theme.textTheme.bodyMedium),
    );
  }

  Widget buildEmptyState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.large),
      child: Text('현재 구매 가능한 티켓이 없습니다.', style: theme.textTheme.bodyMedium),
    );
  }

  List<Widget> buildNoRecommendationState(
    ThemeData theme,
    List<Ticket> tickets,
    Map<String, String> ineligibleReasons,
  ) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.medium),
        child: Text('현재 구매 가능한 티켓이 없습니다.', style: theme.textTheme.bodyMedium),
      ),
      ...tickets.map(
        (ticket) => buildTicketOption(
          ticket,
          isLocked: true,
          isRecommended: false,
          ineligibleReason: ineligibleReasons[ticket.id],
        ),
      ),
    ];
  }

  List<Widget> buildRecommendationState(
    ThemeData theme,
    Ticket recommendedTicket,
    List<Ticket> otherTickets,
    List<Ticket> eligibleTickets,
    Map<String, String> ineligibleReasons,
  ) {
    return [
      Text(
        '추천 티켓',
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: MinglitSpacing.small),
      buildTicketOption(
        recommendedTicket,
        isLocked: false,
        isRecommended: true,
        ineligibleReason: null,
      ),
      if (otherTickets.isNotEmpty) ...[
        const SizedBox(height: MinglitSpacing.medium),
        Text(
          '다른 티켓',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.small),
        ...otherTickets.map((ticket) {
          final isEligible = eligibleTickets.any(
            (eligible) => eligible.id == ticket.id,
          );
          return buildTicketOption(
            ticket,
            isLocked: !isEligible,
            isRecommended: false,
            ineligibleReason: ineligibleReasons[ticket.id],
          );
        }),
      ],
    ];
  }

  List<Widget> buildQuantitySection(ThemeData theme) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '수량',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          buildQuantityStepper(),
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
            calculateTotal(),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
      const SizedBox(height: MinglitSpacing.large),
    ];
  }
}
