import 'package:app_partner/src/features/party/create/wizard/party_create_wizard_controller.dart';
import 'package:app_partner/src/features/party/detail/widgets/party_basic_condition_section.dart';
import 'package:app_partner/src/features/party/entry_group/entry_group_editor_screen.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class Step4EntryRules extends ConsumerWidget {
  const Step4EntryRules({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(partyCreateWizardControllerProvider);
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.partyCreate_title_entryRules,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Text(
            context.l10n.partyCreate_desc_entryRules,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: MinglitSpacing.large),

          // List of Entry Groups
          if (state.entryGroups.isEmpty)
            _buildEmptyState(context)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.entryGroups.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: MinglitSpacing.medium),
              itemBuilder: (context, index) {
                final group = state.entryGroups[index];

                return Card(
                  elevation: 0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(MinglitRadius.card),
                    side: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: MinglitSpacing.medium,
                          vertical: MinglitSpacing.small,
                        ),
                        color: colorScheme.surfaceContainerHighest.withValues(
                          alpha: 0.3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.l10n.partyCreate_label_entryGroupHeader(
                                index + 1,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () =>
                                  notifier.removeEntryGroup(group.id),
                              color: colorScheme.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),

                      // Body (Clickable)
                      InkWell(
                        onTap: () => _showEntryGroupEditor(
                          context,
                          ref,
                          initialGroup: group,
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            cardTheme: const CardThemeData(
                              elevation: 0,
                              margin: EdgeInsets.zero,
                              color: Colors.transparent,
                            ),
                          ),
                          child: PartyBasicConditionSection(
                            party: Party(
                              id: '',
                              partnerId: '',
                              title: '',
                              createdAt: DateTime.now(),
                              updatedAt: DateTime.now(),
                              conditions: [group.toJson()],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

          const SizedBox(height: MinglitSpacing.xlarge),

          // Add Button
          AddActionCard(
            title: context.l10n.partyCreate_button_addEntryGroup,
            subtitle: context.l10n.partyCreate_subtitle_addEntryGroup,
            onTap: () => _showEntryGroupEditor(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Text(context.l10n.partyCreate_empty_entryGroups),
      ),
    );
  }

  Future<void> _showEntryGroupEditor(
    BuildContext context,
    WidgetRef ref, {
    PartyEntryGroup? initialGroup,
  }) async {
    final notifier = ref.read(partyCreateWizardControllerProvider.notifier);

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => EntryGroupEditorScreen(
          initialGroup: initialGroup,
          onSaved: (group) {
            if (initialGroup != null) {
              notifier.updateEntryGroup(group);
            } else {
              notifier.addEntryGroup(group);
            }
          },
        ),
      ),
    );
  }
}
