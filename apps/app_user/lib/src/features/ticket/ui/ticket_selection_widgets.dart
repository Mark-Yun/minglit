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
    return MinglitBadge(
      label: '선택 불가',
      color: theme.colorScheme.onSurfaceVariant,
      compact: true,
    );
  }

  Widget _buildRecommendedBadge(ThemeData theme) {
    return MinglitBadge(
      label: '추천',
      color: theme.colorScheme.primary,
      compact: true,
    );
  }

  Widget buildLoadingState(ThemeData _theme) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MinglitSkeleton(width: 86, height: 14),
        SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          height: 76,
          borderRadius: BorderRadius.all(Radius.circular(MinglitRadius.input)),
        ),
        SizedBox(height: MinglitSpacing.small),
        MinglitSkeleton(
          height: 76,
          borderRadius: BorderRadius.all(Radius.circular(MinglitRadius.input)),
        ),
        SizedBox(height: MinglitSpacing.large),
        MinglitSkeleton(
          height: 48,
          borderRadius: BorderRadius.all(Radius.circular(MinglitRadius.card)),
        ),
      ],
    );
  }

  Widget buildEmptyState(ThemeData theme) {
    return const MinglitEmptyState.card(
      title: '현재 구매 가능한 티켓이 없습니다.',
      icon: Icons.confirmation_number_outlined,
    );
  }

  List<Widget> buildNoRecommendationState(
    ThemeData theme,
    List<Ticket> tickets,
    Map<String, String> ineligibleReasons,
  ) {
    return [
      const MinglitEmptyState.card(
        title: '현재 구매 가능한 티켓이 없습니다.',
        icon: Icons.confirmation_number_outlined,
      ),
      const SizedBox(height: MinglitSpacing.medium),
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
}
