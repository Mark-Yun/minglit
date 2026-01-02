import 'package:app_partner/src/features/party/create/party_create_controller.dart';
import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/create/widgets/party_verification_selector.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:uuid/uuid.dart';

class EntryGroupEditorScreen extends ConsumerStatefulWidget {
  const EntryGroupEditorScreen({
    required this.onSaved,
    this.initialGroup,
    super.key,
  });

  final PartyEntryGroup? initialGroup;
  final void Function(PartyEntryGroup) onSaved;

  @override
  ConsumerState<EntryGroupEditorScreen> createState() =>
      _EntryGroupEditorScreenState();
}

class _EntryGroupEditorScreenState
    extends ConsumerState<EntryGroupEditorScreen> {
  String? _gender;
  int? _minYear;
  int? _maxYear;
  List<String> _selectedVerificationIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialGroup != null) {
      _gender = widget.initialGroup!.gender;
      _minYear = widget.initialGroup!.birthYearRange?['min'] as int?;
      _maxYear = widget.initialGroup!.birthYearRange?['max'] as int?;
      _selectedVerificationIds = List<String>.from(
        widget.initialGroup!.requiredVerificationIds,
      );
    } else {
      _minYear = 1995;
      _maxYear = 2005;
    }
  }

  void _submit() {
    Map<String, dynamic>? birthYearRange;
    if (_minYear != null || _maxYear != null) {
      birthYearRange = {
        'min': _minYear,
        'max': _maxYear,
      }..removeWhere((k, v) => v == null);
    }

    final group = PartyEntryGroup(
      id: widget.initialGroup?.id ?? const Uuid().v4(),
      gender: _gender,
      birthYearRange: birthYearRange,
      requiredVerificationIds: _selectedVerificationIds,
    );

    widget.onSaved(group);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final verificationsAsync = ref.watch(partyVerificationTypesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialGroup == null
              ? context.l10n.entryGroup_title_add
              : context.l10n.entryGroup_title_edit,
        ),
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
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.secondaryContainer;
                  }
                  return null;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.onSecondaryContainer;
                  }
                  return theme.colorScheme.onSurface;
                }),
                iconColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return theme.colorScheme.onSecondaryContainer;
                  }
                  return theme.colorScheme.onSurface;
                }),
              ),
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
                  child: NumberStepperInput(
                    label: context.l10n.entryGroup_label_minYear,
                    value: _minYear ?? 1995,
                    min: 1950,
                    max: 2010,
                    onChanged: (val) => setState(() => _minYear = val),
                    suffixText: context.l10n.entryGroup_suffix_year,
                  ),
                ),
                const SizedBox(width: MinglitSpacing.medium),
                Expanded(
                  child: NumberStepperInput(
                    label: context.l10n.entryGroup_label_maxYear,
                    value: _maxYear ?? 2005,
                    min: 1950,
                    max: 2010,
                    onChanged: (val) => setState(() => _maxYear = val),
                    suffixText: context.l10n.entryGroup_suffix_year,
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
