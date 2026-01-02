import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/widgets/party_verification_selector.dart';
import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:uuid/uuid.dart';

class PartyEntryGroupEditorScreen extends ConsumerStatefulWidget {
  const PartyEntryGroupEditorScreen({super.key});

  @override
  ConsumerState<PartyEntryGroupEditorScreen> createState() =>
      _PartyEntryGroupEditorScreenState();
}

class _PartyEntryGroupEditorScreenState
    extends ConsumerState<PartyEntryGroupEditorScreen> {
  String? _gender;
  final _minYearController = TextEditingController();
  final _maxYearController = TextEditingController();
  // State is mutable
  // ignore: prefer_final_fields
  List<String> _selectedVerificationIds = [];

  @override
  void dispose() {
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  void _submit() {
    final min = int.tryParse(_minYearController.text);
    final max = int.tryParse(_maxYearController.text);

    Map<String, dynamic>? birthYearRange;
    if (min != null || max != null) {
      birthYearRange = {
        'min': min,
        'max': max,
      }..removeWhere((k, v) => v == null);
    }

    final group = PartyEntryGroup(
      id: const Uuid().v4(),
      gender: _gender,
      birthYearRange: birthYearRange,
      requiredVerificationIds: _selectedVerificationIds,
    );

    ref.read(partyCreateWizardControllerProvider.notifier).addEntryGroup(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(partyVerificationTypesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.entryGroup_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Gender
            Text(
              context.l10n.entryGroup_label_gender,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: MinglitSpacing.small),
            SegmentedButton<String?>(
              segments: [
                ButtonSegment(
                  value: null,
                  label: Text(context.l10n.entryGroup_option_any),
                ),
                ButtonSegment(
                  value: 'male',
                  label: Text(context.l10n.entryGroup_option_male),
                ),
                ButtonSegment(
                  value: 'female',
                  label: Text(context.l10n.entryGroup_option_female),
                ),
              ],
              selected: {_gender},
              onSelectionChanged: (newSelection) {
                setState(() => _gender = newSelection.first);
              },
            ),
            const SizedBox(height: MinglitSpacing.large),

            // 2. Birth Year
            Text(
              context.l10n.entryGroup_label_birthYear,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _minYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.entryGroup_label_minYear,
                      suffixText: context.l10n.entryGroup_suffix_year,
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: TextFormField(
                    controller: _maxYearController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: context.l10n.entryGroup_label_maxYear,
                      suffixText: context.l10n.entryGroup_suffix_year,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.large),

            // 3. Verifications
            Text(
              context.l10n.entryGroup_label_verification,
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: MinglitSpacing.small),
            PartyVerificationSelector(
              verificationsAsync: verificationsAsync,
              selectedVerificationIds: _selectedVerificationIds,
              onToggle: (id) {
                setState(() {
                  if (_selectedVerificationIds.contains(id)) {
                    _selectedVerificationIds.remove(id);
                  } else {
                    _selectedVerificationIds.add(id);
                  }
                });
              },
              onAddTap: () {
                final partnerInfo = ref.read(currentPartnerInfoProvider);
                // Trigger create verification route
                PartyCreateCoordinator(
                  context,
                ).goToCreateVerification(partnerInfo.value?.id);
              },
            ),
            const SizedBox(height: MinglitSpacing.xlarge),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              child: Text(context.l10n.entryGroup_button_complete),
            ),
          ),
        ),
      ),
    );
  }
}
