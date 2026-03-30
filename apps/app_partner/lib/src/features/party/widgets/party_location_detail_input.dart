import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyLocationDetailInput extends StatelessWidget {
  const PartyLocationDetailInput({
    required this.addressDetailController,
    required this.directionsController,
    this.onAddressDetailChanged,
    this.onDirectionsChanged,
    this.enabled = true,
    super.key,
  });

  final TextEditingController addressDetailController;
  final TextEditingController directionsController;
  final ValueChanged<String>? onAddressDetailChanged;
  final ValueChanged<String>? onDirectionsChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.partyCreate_label_addressDetail,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        TextFormField(
          controller: addressDetailController,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: enabled
                ? context.l10n.partyCreate_hint_addressDetail
                : '장소를 먼저 선택해주세요.',
            fillColor: enabled
                ? null
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            filled: true,
          ),
          onChanged: onAddressDetailChanged,
        ),
        const SizedBox(height: MinglitSpacing.large),
        Text(
          context.l10n.partyCreate_label_directions,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        TextFormField(
          controller: directionsController,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: enabled
                ? context.l10n.partyCreate_hint_directions
                : '장소를 먼저 선택해주세요.',
            fillColor: enabled
                ? null
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            filled: true,
          ),
          maxLines: 3,
          onChanged: onDirectionsChanged,
        ),
      ],
    );
  }
}
