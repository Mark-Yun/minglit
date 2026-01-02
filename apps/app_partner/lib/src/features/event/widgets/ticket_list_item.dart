import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Ticket Status Header**
///
/// Displays the summary of ticket issuance vs capacity in a minimal style.
class TicketStatusHeader extends StatelessWidget {
  const TicketStatusHeader({
    required this.totalIssued,
    required this.maxParticipants,
    super.key,
  });

  final int totalIssued;
  final int? maxParticipants;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.xxsmall,
        vertical: MinglitSpacing.small,
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Text(
            context.l10n.ticketList_header_title,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              children: [
                TextSpan(
                  text: '$totalIssued',
                  style: TextStyle(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' / ${maxParticipants ?? '-'}매 발행',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// **Ticket List Item**
///
/// A reusable widget to display ticket information in a list
/// with minimal design.
class TicketListItem extends StatelessWidget {
  const TicketListItem({
    required this.ticket,
    this.entryGroups = const [],
    this.onTap,
    this.trailing,
    this.showStats = true,
    super.key,
  });

  final Ticket ticket;
  final List<PartyEntryGroup> entryGroups;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showStats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currencyFormat = NumberFormat.currency(
      locale: 'ko_KR',
      symbol: '₩',
    );

    // Filter linked entry groups
    final linkedGroups = entryGroups
        .where((g) => ticket.targetEntryGroupIds.contains(g.id))
        .toList();

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              // Ticket Icon
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
              const SizedBox(width: MinglitSpacing.medium),

              // Ticket Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (linkedGroups.isNotEmpty) ...[
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: linkedGroups.map((g) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              g.label ?? _getGroupSummary(context, g),
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: MinglitSpacing.xxsmall),
                    ],
                    Text(
                      ticket.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      '${currencyFormat.format(ticket.price)} · '
                      '${ticket.quantity}매 발행',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing / Stats
              if (trailing != null)
                trailing!
              else if (showStats) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      context.l10n.ticketList_label_sold(ticket.soldCount),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      ticket.status == 'on_sale'
                          ? context.l10n.ticketList_status_onSale
                          : context.l10n.ticketList_status_soldOut,
                      style: TextStyle(
                        fontSize: 9,
                        color: ticket.status == 'on_sale'
                            ? colorScheme.outline
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

  String _getGroupSummary(BuildContext context, PartyEntryGroup group) {
    final ageRange = group.birthYearRange;
    var ageText = context.l10n.entryGroup_option_anyYear;
    if (ageRange != null) {
      final min = ageRange['min'];
      final max = ageRange['max'];
      if (min != null && max != null) {
        ageText = '$min~$max';
      } else if (min != null) {
        ageText = '$min~';
      } else if (max != null) {
        ageText = '~$max';
      }
    }
    // Summary logic kept simple for list tags
    final gInitial = group.gender == 'male'
        ? '남'
        : group.gender == 'female'
            ? '여'
            : '무관';
    return '$gInitial($ageText)';
  }
}

/// **Ticket List View**
///
/// A list of [TicketListItem] with empty state handling.
class TicketListView extends StatelessWidget {
  const TicketListView({
    required this.tickets,
    this.entryGroups = const [],
    this.maxParticipants,
    this.onTicketTap,
    this.onCreatePressed,
    this.showStats = true,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
    super.key,
  });

  final List<Ticket> tickets;
  final List<PartyEntryGroup> entryGroups;
  final int? maxParticipants;
  final void Function(Ticket)? onTicketTap;
  final VoidCallback? onCreatePressed;
  final bool showStats;
  final bool shrinkWrap;
  final ScrollPhysics physics;

  @override
  Widget build(BuildContext context) {
    final totalIssued = tickets.fold(0, (sum, t) => sum + t.quantity);

    if (tickets.isEmpty) {
      if (onCreatePressed != null) {
        return AddActionCard(
          title: context.l10n.ticketList_add_title,
          subtitle: context.l10n.ticketList_add_subtitle,
          iconData: Icons.confirmation_number_outlined,
          onTap: onCreatePressed!,
        );
      }
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (maxParticipants != null)
          TicketStatusHeader(
            totalIssued: totalIssued,
            maxParticipants: maxParticipants,
          ),
        ListView.separated(
          shrinkWrap: shrinkWrap,
          physics: physics,
          itemCount: tickets.length + (onCreatePressed != null ? 1 : 0),
          separatorBuilder: (context, index) =>
              const SizedBox(height: MinglitSpacing.small),
          itemBuilder: (context, index) {
            if (index == tickets.length) {
              return Padding(
                padding: const EdgeInsets.only(top: MinglitSpacing.xxsmall),
                child: AddActionCard(
                  title: context.l10n.ticketList_add_title,
                  subtitle: context.l10n.ticketList_add_subtitle,
                  iconData: Icons.add,
                  onTap: onCreatePressed!,
                ),
              );
            }
            final ticket = tickets[index];
            return TicketListItem(
              ticket: ticket,
              entryGroups: entryGroups,
              showStats: showStats,
              onTap: onTicketTap != null ? () => onTicketTap!(ticket) : null,
            );
          },
        ),
      ],
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
            size: 32,
            color: colorScheme.outline,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            context.l10n.ticketList_empty,
            style:
                theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
          ),
        ],
      ),
    );
  }
}