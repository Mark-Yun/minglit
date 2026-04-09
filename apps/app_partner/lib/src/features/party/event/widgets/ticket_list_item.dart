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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Expanded(
            child: Text(
              context.l10n.ticketList_header_title,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: MinglitSpacing.small),
          Flexible(
            child: Text(
              context.l10n.ticketList_header_summary(
                totalIssued,
                maxParticipants ?? 0,
              ),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
    final currencyFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

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
          color: colorScheme.outlineVariant.withValues(
            alpha: MinglitOpacity.strong,
          ),
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
                    alpha: MinglitOpacity.strong,
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
                              horizontal: MinglitSpacing.xsmall,
                              vertical: MinglitSpacing.xxsmall,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer.withValues(
                                alpha: MinglitOpacity.muted,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: Text(
                              g.label ?? _getGroupSummary(context, g),
                              style: theme.textTheme.bodySmall!.copyWith(
                                color: colorScheme.primary,
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
                    // Fix #596: bodySmall+fontSize:11 → labelSmall (11px)
                    Text(
                      '${currencyFormat.format(ticket.price)} · '
                      '${ticket.quantity}매 발행',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Trailing / Stats
              if (trailing != null)
                Flexible(child: trailing!)
              else if (showStats) ...[
                const SizedBox(width: MinglitSpacing.small),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        context.l10n.ticketList_label_sold(ticket.soldCount),
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: MinglitSpacing.xxsmall),
                      Text(
                        ticket.status == 'on_sale'
                            ? context.l10n.ticketList_status_onSale
                            : context.l10n.ticketList_status_soldOut,
                        textAlign: TextAlign.right,
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: ticket.status == 'on_sale'
                              ? colorScheme.outline
                              : colorScheme.error,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getGroupSummary(BuildContext context, PartyEntryGroup group) {
    final min = group.birthYearMin;
    final max = group.birthYearMax;
    var ageText = context.l10n.entryGroup_option_anyYear;

    if (min != null && max != null) {
      ageText = '$min~$max';
    } else if (min != null) {
      ageText = '$min~';
    } else if (max != null) {
      ageText = '~$max';
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
      return SizedBox(
        width: double.infinity,
        child: MinglitEmptyState.card(
          title: context.l10n.ticketList_empty,
          icon: Icons.confirmation_number_outlined,
        ),
      );
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

}
