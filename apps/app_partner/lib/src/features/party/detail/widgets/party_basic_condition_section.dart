import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyBasicConditionSection extends StatelessWidget {
  const PartyBasicConditionSection({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final conditions = party.conditions;

    final gender = conditions['gender'] as String?;
    final ageRange = conditions['age_range'] as Map<String, dynamic>?;

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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Row(
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
        ),
      ),
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
