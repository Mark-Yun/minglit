import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyLocationDetailInput extends StatelessWidget {
  const PartyLocationDetailInput({
    required this.addressDetailController,
    required this.directionsController,
    this.onAddressDetailChanged,
    this.onDirectionsChanged,
    super.key,
  });

  final TextEditingController addressDetailController;
  final TextEditingController directionsController;
  final ValueChanged<String>? onAddressDetailChanged;
  final ValueChanged<String>? onDirectionsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PartySectionTitle('상세 주소 (선택)'),
        TextFormField(
          controller: addressDetailController,
          decoration: const InputDecoration(
            hintText: '예: 2층 201호, 루프탑 등',
          ),
          onChanged: onAddressDetailChanged,
        ),
        const SizedBox(height: MinglitSpacing.large),
        const PartySectionTitle('오시는 길 안내 (선택)'),
        TextFormField(
          controller: directionsController,
          decoration: const InputDecoration(
            hintText: '예: 강남역 11번 출구에서 도보 5분 거리입니다.',
          ),
          maxLines: 3,
          onChanged: onDirectionsChanged,
        ),
      ],
    );
  }
}
