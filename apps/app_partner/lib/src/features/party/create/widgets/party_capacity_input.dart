import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCapacityInput extends StatelessWidget {
  const PartyCapacityInput({
    required this.minController,
    required this.maxController,
    required this.controller,
    super.key,
  });

  final TextEditingController minController;
  final TextEditingController maxController;
  final PartyCreateController controller;

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
                validator: controller.validateCapacity,
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
                validator: (v) => controller.validateMaxCapacity(
                  v,
                  minController.text,
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
