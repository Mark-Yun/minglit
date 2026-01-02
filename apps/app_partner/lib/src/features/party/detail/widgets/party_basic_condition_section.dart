import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicConditionSection extends ConsumerWidget {
  const PartyBasicConditionSection({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conditions = party.conditions;

    if (conditions.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Text(
            '입장 조건이 없습니다.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < conditions.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Divider(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              _buildConditionGroup(
                context,
                ref,
                conditions[i] as Map<String, dynamic>,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConditionGroup(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> cond,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verifIds =
        List<String>.from(cond['required_verification_ids'] as List? ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gender & Age Row
        _buildConditionRow(context, cond),

        // 2. Verifications for this group
        if (verifIds.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.medium),
          Text(
            '필수 인증',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          _VerificationBadges(verifIds: verifIds),
        ],
      ],
    );
  }

  Widget _buildConditionRow(BuildContext context, Map<String, dynamic> cond) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final gender = cond['gender'] as String?;
    final ageRange = cond['age_range'] as Map<String, dynamic>?;

    var genderText = '성별 무관';
    if (gender == 'male') genderText = '남성 전용';
    if (gender == 'female') genderText = '여성 전용';

    var ageText = '나이 무관';
    if (ageRange != null) {
      final min = ageRange['min'];
      final max = ageRange['max'];
      if (min != null && max != null) {
        ageText = '$min~$max년생';
      } else if (min != null) {
        ageText = '$min년생 이후';
      } else if (max != null) {
        ageText = '$max년생 이전';
      }
    }

    return Row(
      children: [
        Expanded(
          child: _buildConditionItem(
            context,
            Icons.wc,
            '성별 조건',
            genderText,
          ),
        ),
        SizedBox(
          height: 24,
          child: VerticalDivider(
            color: colorScheme.outlineVariant,
            width: MinglitSpacing.medium,
          ),
        ),
        Expanded(
          child: _buildConditionItem(
            context,
            Icons.cake_outlined,
            '나이 조건',
            ageText,
          ),
        ),
      ],
    );
  }

  Widget _buildConditionItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: MinglitIconSize.small,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
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
        spacing: 6,
        runSpacing: 6,
        children: list
            .map(
              (v) => Chip(
                label: Text(v.displayName),
                avatar: const Icon(Icons.verified, size: 14),
                visualDensity: VisualDensity.compact,
                labelStyle: const TextStyle(fontSize: 11),
                backgroundColor:
                    colorScheme.primaryContainer.withValues(alpha: 0.3),
                side: BorderSide.none,
              ),
            )
            .toList(),
      ),
      loading: () => const MinglitSkeleton(height: 32, width: 100),
      error:
          (e, s) => const Icon(
            Icons.error_outline,
            size: 16,
            color: Colors.red,
          ),
    );
  }
}
