import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Entry Group Detail**
///
/// A minimal widget that displays the details of a single [PartyEntryGroup].
/// Adheres strictly to the Minglit design system using themed text styles.
class EntryGroupDetail extends StatelessWidget {
  const EntryGroupDetail({
    required this.group,
    this.genderLabel = '성별',
    this.birthYearLabel = '나이',
    this.anyLabel = '제한 없음',
    this.anyYearLabel = '나이 제한 없음',
    super.key,
  });

  final PartyEntryGroup group;
  final String genderLabel;
  final String birthYearLabel;
  final String anyLabel;
  final String anyYearLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (group.label != null && group.label!.isNotEmpty) ...[
          Text(
            group.label!,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
        ],
        _buildConditionRow(context),
        if (group.requiredVerificationIds.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          _VerificationBadges(verifIds: group.requiredVerificationIds),
        ],
      ],
    );
  }

  Widget _buildConditionRow(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gender = group.gender;
    final birthYearRange = group.birthYearRange;

    var genderText = anyLabel;
    if (gender == 'male') genderText = '남성';
    if (gender == 'female') genderText = '여성';

    var birthYearText = anyYearLabel;
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
        // Year First
        Icon(
          Icons.cake_outlined,
          size: MinglitIconSize.xsmall,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          birthYearText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(width: MinglitSpacing.large),
        // Gender Second
        Icon(
          Icons.wc,
          size: MinglitIconSize.xsmall,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 6),
        Text(
          genderText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurface,
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
    final verificationsAsync = ref.watch(
      verificationsByIdsProvider(verifIds),
    );

    return verificationsAsync.when(
      data: (List<Verification> list) => Wrap(
        spacing: MinglitSpacing.small,
        runSpacing: MinglitSpacing.small,
        children: list
            .map(
              (v) => MinglitChip(
                label: v.displayName,
                icon: Icons.verified_user_outlined,
              ),
            )
            .toList(),
      ),
      loading: () => const MinglitSkeleton(height: 32, width: 80),
      error: (Object e, StackTrace s) => const SizedBox.shrink(),
    );
  }
}
