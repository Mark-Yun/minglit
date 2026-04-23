import 'package:app_partner/src/features/party/create/party_create_coordinator.dart';
import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyEntryGroupManagementScreen extends ConsumerWidget {
  const PartyEntryGroupManagementScreen({
    required this.partyId,
    super.key,
  });

  final String partyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partyAsync = ref.watch(partyDetailProvider(partyId));
    final coordinator = ref.read(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: context.l10n.partyDetail_section_entranceCondition,
      ),
      body: MinglitAsyncValueWidget(
        value: partyAsync,
        data: (party) {
          final groups = party.entryGroups ?? [];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (groups.isEmpty)
                  MinglitEmptyState.inline(
                    title: context.l10n.partyCreate_empty_entryGroups,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: groups.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MinglitSpacing.medium),
                    itemBuilder: (context, index) {
                      final group = groups[index];
                      return Card(
                        elevation: 0,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MinglitRadius.card,
                          ),
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withValues(
                              alpha: MinglitOpacity.strong,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MinglitSpacing.medium,
                                vertical: MinglitSpacing.small,
                              ),
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(
                                    alpha: MinglitOpacity.muted,
                                  ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    context.l10n
                                        .partyCreate_label_entryGroupHeader(
                                          index + 1,
                                        ),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () =>
                                        coordinator.removePartyEntryGroup(
                                          partyId,
                                          group.id,
                                          context,
                                        ),
                                    color: colorScheme.onSurfaceVariant,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () => _openGroupEditor(
                                context,
                                ref,
                                coordinator: coordinator,
                                initialGroup: group,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(
                                  MinglitSpacing.medium,
                                ),
                                child: EntryGroupDetail(
                                  group: group,
                                  anyLabel: context.l10n.entryGroup_option_any,
                                  anyYearLabel:
                                      context.l10n.entryGroup_option_anyYear,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: MinglitSpacing.xlarge),
                AddActionCard(
                  title: context.l10n.partyCreate_button_addEntryGroup,
                  subtitle: context.l10n.partyCreate_subtitle_addEntryGroup,
                  onTap: () => _openGroupEditor(
                    context,
                    ref,
                    coordinator: coordinator,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openGroupEditor(
    BuildContext context,
    WidgetRef ref, {
    required PartyDetailCoordinator coordinator,
    PartyEntryGroup? initialGroup,
  }) async {
    final createCoordinator = PartyCreateCoordinator(context, ref: ref);
    await createCoordinator.goToEntryGroupEditor(
      initialGroup: initialGroup,
      onSaved: (group) async {
        if (!context.mounted) return;
        if (initialGroup != null) {
          await coordinator.updatePartyEntryGroup(partyId, group, context);
        } else {
          await coordinator.addPartyEntryGroup(partyId, group, context);
        }
      },
    );
  }
}
