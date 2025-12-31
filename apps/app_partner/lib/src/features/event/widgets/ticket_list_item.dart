import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Ticket List Item**
///
/// A reusable widget to display ticket information in a list.
class TicketListItem extends StatelessWidget {
  const TicketListItem({
    required this.ticket,
    this.onTap,
    this.trailing,
    super.key,
  });

  final EventTicket ticket;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              // Ticket Icon with Gender Badge
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    padding: const EdgeInsets.all(MinglitSpacing.small),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer.withValues(
                        alpha: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(MinglitRadius.input),
                    ),
                    child: Icon(
                      Icons.local_activity,
                      color: colorScheme.primary,
                      size: MinglitIconSize.medium,
                    ),
                  ),
                  if (ticket.gender != null)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: ticket.gender == 'male'
                            ? Colors.blue
                            : Colors.pinkAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Icon(
                        ticket.gender == 'male' ? Icons.male : Icons.female,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: MinglitSpacing.medium),

              // Ticket Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ticket.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      '${currencyFormat.format(ticket.price)} · '
                      '${ticket.quantity}매 발행',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (ticket.minBirthYear != null ||
                        ticket.maxBirthYear != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '나이제한: ${_getAgeRangeText()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.secondary,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Trailing / Stats
              if (trailing != null)
                trailing!
              else ...[
                const SizedBox(width: MinglitSpacing.small),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${ticket.soldCount}매 판매',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      ticket.status == 'on_sale' ? '판매중' : '판매중지',
                      style: TextStyle(
                        fontSize: 10,
                        color: ticket.status == 'on_sale'
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getAgeRangeText() {
    if (ticket.minBirthYear != null && ticket.maxBirthYear != null) {
      return '${ticket.minBirthYear}~${ticket.maxBirthYear}년생';
    } else if (ticket.minBirthYear != null) {
      return '${ticket.minBirthYear}년생 이후';
    } else if (ticket.maxBirthYear != null) {
      return '${ticket.maxBirthYear}년생 이전';
    }
    return '제한 없음';
  }
}

/// **Ticket List View**
///
/// A list of [TicketListItem] with empty state handling.
class TicketListView extends StatelessWidget {
  const TicketListView({
    required this.tickets,
    this.onTicketTap,
    this.onCreatePressed,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    super.key,
  });

  final List<EventTicket> tickets;
  final void Function(EventTicket)? onTicketTap;
  final VoidCallback? onCreatePressed;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: tickets.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: MinglitSpacing.small),
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return TicketListItem(
          ticket: ticket,
          onTap: onTicketTap != null ? () => onTicketTap!(ticket) : null,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Column(
        children: [
          Icon(
            Icons.confirmation_number_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: MinglitSpacing.small),
          const Text('등록된 티켓이 없습니다.'),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            '티켓을 생성하여 판매를 시작해보세요.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (onCreatePressed != null) ...[
            const SizedBox(height: MinglitSpacing.medium),
            ElevatedButton.icon(
              onPressed: onCreatePressed,
              icon: const Icon(Icons.add, size: MinglitIconSize.small),
              label: const Text('티켓 생성하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(160, 44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
