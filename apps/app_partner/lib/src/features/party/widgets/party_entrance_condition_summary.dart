import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyEntranceConditionSummary extends ConsumerWidget {
  const PartyEntranceConditionSummary({
    required this.entryGroups,
    this.onGroupTap,
    super.key,
  });

  final List<PartyEntryGroup> entryGroups;
  final void Function(PartyEntryGroup)? onGroupTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (entryGroups.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(MinglitSpacing.large),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: MinglitOpacity.muted),
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: Column(
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 32,
              color: colorScheme.outline,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              context.l10n.partyCreate_empty_entryGroups,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < entryGroups.length; i++) ...[
          Container(
            margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: InkWell(
              onTap: onGroupTap != null
                  ? () => onGroupTap!(entryGroups[i])
                  : null,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: EntryGroupDetail(
                  group: entryGroups[i],
                  anyLabel: context.l10n.entryGroup_option_any,
                  anyYearLabel: context.l10n.entryGroup_option_anyYear,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
