import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCapacityInput extends StatelessWidget {
  const PartyCapacityInput({
    required this.minCount,
    required this.maxCount,
    required this.onMinChanged,
    super.key,
  });

  final int minCount;
  final int maxCount;
  final ValueChanged<int> onMinChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: NumberStepperInput(
                label: '최소 확정',
                value: minCount,
                onChanged: onMinChanged,
                suffixText: '명',
                min: 1,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: MinglitOpacity.muted,
                  ),
                  borderRadius: BorderRadius.circular(MinglitRadius.input),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최대 정원',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: MinglitSpacing.xsmall),
                    Text(
                      '$maxCount명',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.small),
          child: const Column(
            children: [
              _PolicyRow('파티 3일 전까지 최소 확정 인원에 미달한 경우 파티는 취소되고 자동 환불됩니다.'),
              SizedBox(height: MinglitSpacing.xxsmall),
              _PolicyRow('최대 정원은 티켓 수량의 합계로 자동 설정됩니다.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  const _PolicyRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.info_outline, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(child: Text(text, style: MinglitTextStyles.infoText(context))),
      ],
    );
  }
}
