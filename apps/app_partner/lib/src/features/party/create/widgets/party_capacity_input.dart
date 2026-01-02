import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCapacityInput extends StatelessWidget {
  const PartyCapacityInput({
    required this.minController,
    required this.maxController,
    this.onMinChanged,
    this.onMaxChanged,
    this.minValidator,
    this.maxValidator,
    super.key,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final ValueChanged<String>? onMinChanged;
  final ValueChanged<String>? onMaxChanged;
  final FormFieldValidator<String>? minValidator;
  final FormFieldValidator<String>? maxValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: minController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '최소 확정',
                  suffixText: '명',
                ),
                onChanged: onMinChanged,
                validator: minValidator,
              ),
            ),
            const SizedBox(width: MinglitSpacing.medium),
            Expanded(
              child: TextFormField(
                controller: maxController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '최대 정원',
                  suffixText: '명',
                ),
                onChanged: onMaxChanged,
                validator: maxValidator,
              ),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.small),
        Container(
          padding: const EdgeInsets.all(MinglitSpacing.small),
          child: const Column(
            children: [
              _PolicyRow(
                '파티 3일 전까지 최소 확정 인원에 미달한 경우 파티는 취소되고 자동 환불됩니다.',
              ),
              SizedBox(height: MinglitSpacing.xxsmall),
              _PolicyRow(
                '최대 정원에 도달할 경우 티켓 판매가 즉시 자동 종료됩니다.',
              ),
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
        Icon(
          Icons.info_outline,
          size: 14,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: Text(
            text,
            style: MinglitTextStyles.infoText(context),
          ),
        ),
      ],
    );
  }
}
