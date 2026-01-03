import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyConditionsInput extends StatelessWidget {
  const PartyConditionsInput({
    required this.conditions,
    required this.onChanged,
    super.key,
  });

  final Map<String, dynamic> conditions;
  final void Function(Map<String, dynamic>) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gender = conditions['gender'] as String?;
    final birthYearRange =
        conditions['birth_year_range'] as Map<String, dynamic>?;
    final minAge = birthYearRange?['min'] as int?;
    final maxAge = birthYearRange?['max'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Gender Selection
        Text('성별 제한', style: theme.textTheme.labelMedium),
        const SizedBox(height: MinglitSpacing.small),
        Row(
          children: [
            _GenderChip(
              label: '제한 없음',
              isSelected: gender == null,
              onSelected: (_) => _updateGender(null),
            ),
            const SizedBox(width: MinglitSpacing.small),
            _GenderChip(
              label: '남성만',
              isSelected: gender == 'male',
              onSelected: (_) => _updateGender('male'),
            ),
            const SizedBox(width: MinglitSpacing.small),
            _GenderChip(
              label: '여성만',
              isSelected: gender == 'female',
              onSelected: (_) => _updateGender('female'),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.large),

        // 2. Age Range
        Text('나이 제한 (출생년도)', style: theme.textTheme.labelMedium),
        const SizedBox(height: MinglitSpacing.small),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: minAge?.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '최소 (예: 1990)',
                  suffixText: '년생',
                ),
                onChanged: (val) => _updateAge(
                  min: int.tryParse(val),
                  max: maxAge,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: MinglitSpacing.small),
              child: Text('~'),
            ),
            Expanded(
              child: TextFormField(
                initialValue: maxAge?.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '최대 (예: 2000)',
                  suffixText: '년생',
                ),
                onChanged: (val) => _updateAge(
                  min: minAge,
                  max: int.tryParse(val),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.xsmall),
        Text(
          '입력하지 않으면 제한 없이 모든 연령대가 참여 가능합니다.',
          style: MinglitTextStyles.infoText(context),
        ),
      ],
    );
  }

  void _updateGender(String? value) {
    final newConditions = Map<String, dynamic>.from(conditions);
    if (value == null) {
      newConditions.remove('gender');
    } else {
      newConditions['gender'] = value;
    }
    onChanged(newConditions);
  }

  void _updateAge({int? min, int? max}) {
    final newConditions = Map<String, dynamic>.from(conditions);
    if (min == null && max == null) {
      newConditions.remove('birth_year_range');
    } else {
      newConditions['birth_year_range'] = {
        'min': min,
        'max': max,
      }..removeWhere((k, v) => v == null);
    }
    onChanged(newConditions);
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : null,
          fontWeight: isSelected ? FontWeight.bold : null,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: colorScheme.secondary,
      showCheckmark: false,
    );
  }
}
