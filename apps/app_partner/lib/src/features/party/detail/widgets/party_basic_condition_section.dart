import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
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

    // Borderless minimal design
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          InkWell(
            onTap: onGroupTap != null ? () => onGroupTap!(groups[i]) : null,
            borderRadius: BorderRadius.circular(MinglitRadius.small),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: MinglitSpacing.small,
                horizontal: 4,
              ),
              child: _buildConditionGroup(context, ref, groups[i]),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildConditionGroup(
    BuildContext context,
    WidgetRef ref,
    PartyEntryGroup group,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verifIds = group.requiredVerificationIds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.label != null && group.label!.isNotEmpty) ...[
          Text(
            group.label!,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
        ],
        _buildConditionRow(context, group),
        if (verifIds.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.small),
          _VerificationBadges(verifIds: verifIds),
        ],
      ],
    );
  }

  Widget _buildConditionRow(BuildContext context, PartyEntryGroup group) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gender = group.gender;
    final birthYearRange = group.birthYearRange;

    var genderText = context.l10n.entryGroup_option_any;
    if (gender == 'male') genderText = context.l10n.entryGroup_option_male;
    if (gender == 'female') genderText = context.l10n.entryGroup_option_female;

    var birthYearText = context.l10n.entryGroup_option_anyYear;
    if (birthYearRange != null) {
      final min = birthYearRange['min'];
      final max = birthYearRange['max'];
      if (min != null && max != null) {
        birthYearText = '$min~$max년생';
      } else if (min != null) {
        birthYearText = '$min년생 이후';
      } else if (max != null) {
        birthYearText = '$max년생 이전';
      }
    }

    return Row(
      children: [
        Icon(Icons.wc, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(
          genderText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: MinglitSpacing.medium),
        Icon(
          Icons.cake_outlined,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          birthYearText,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _VerificationBadges extends ConsumerWidget {
  const _VerificationBadges({required this.verifIds});
  final List<String> verifIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final verificationsAsync = ref.watch(verificationsByIdsProvider(verifIds));
    final colorScheme = Theme.of(context).colorScheme;

    return verificationsAsync.when(
      data: (list) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: list
            .map(
              (v) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified, size: 10, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      v.displayName,
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
      loading: () => const MinglitSkeleton(height: 20, width: 60),
      error: (e, s) => const SizedBox.shrink(),
    );
  }
}
