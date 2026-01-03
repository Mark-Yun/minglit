import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicConditionSection extends ConsumerWidget {
  const PartyBasicConditionSection({
    required this.party,
    this.onGroupTap,
    super.key,
  });

  final Party party;
  final void Function(PartyEntryGroup)? onGroupTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final groups = party.entryGroups;

    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
        child: Text(
          '입장 조건이 없습니다.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
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
              onTap: onGroupTap != null ? () => onGroupTap!(groups[i]) : null,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                child: EntryGroupDetail(
                  group: groups[i],
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
