import 'package:app_partner/src/features/party/create/widgets/party_section_title.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
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
        PartySectionTitle(context.l10n.partyCreate_label_addressDetail),
        TextFormField(
          controller: addressDetailController,
          decoration: InputDecoration(
            hintText: context.l10n.partyCreate_hint_addressDetail,
          ),
          onChanged: onAddressDetailChanged,
        ),
        const SizedBox(height: MinglitSpacing.large),
        PartySectionTitle(context.l10n.partyCreate_label_directions),
        TextFormField(
          controller: directionsController,
          decoration: InputDecoration(
            hintText: context.l10n.partyCreate_hint_directions,
          ),
          maxLines: 3,
          onChanged: onDirectionsChanged,
        ),
      ],
    );
  }
}
