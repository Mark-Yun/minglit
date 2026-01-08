import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';

class PartyCapacitySummary extends StatelessWidget {
  const PartyCapacitySummary({
    required this.minCount,
    required this.maxCount,
    super.key,
  });

  final int minCount;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          context.l10n.partyCreate_label_capacity,
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        Text(
          '$minCount ~ $maxCount${context.l10n.common_unit_person}',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
