import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Party Tickets Summary**
///
/// Displays a list of tickets with a status header.
/// Reused in Party Detail and Review steps.
class PartyTicketsSummary extends StatelessWidget {
  const PartyTicketsSummary({
    required this.tickets,
    required this.entryGroups,
    this.maxCapacity,
    this.onTicketTap,
    this.onCreatePressed,
    this.showStats = true,
    this.showError = false,
    super.key,
  });

  final List<Ticket> tickets;
  final List<PartyEntryGroup> entryGroups;
  final int? maxCapacity;
  final void Function(Ticket)? onTicketTap;
  final VoidCallback? onCreatePressed;
  final bool showStats;
  final bool showError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (tickets.isEmpty && showError) {
      return Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          border: Border.all(
            color: theme.colorScheme.error.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          context.l10n.wizard_review_empty_tickets,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    return TicketListView(
      tickets: tickets,
      entryGroups: entryGroups,
      maxParticipants: maxCapacity,
      onTicketTap: onTicketTap,
      onCreatePressed: onCreatePressed,
      showStats: showStats,
    );
  }
}
