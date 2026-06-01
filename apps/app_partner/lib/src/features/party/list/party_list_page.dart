import 'package:app_partner/src/features/party/list/party_help_sections.dart';
import 'package:app_partner/src/features/party/list/party_list_controller.dart';
import 'package:app_partner/src/features/party/list/party_list_coordinator.dart';
import 'package:app_partner/src/features/party/list/widgets/party_list_item.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyListPage extends ConsumerWidget {
  const PartyListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partiesAsync = ref.watch(partyListProvider);
    final coordinator = ref.read(partyListCoordinatorProvider);

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(
        title: '파티 관리',
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            iconSize: 22,
            tooltip: '도움말',
            onPressed: () => showMinglitHelpSheet(
              context: context,
              title: '파티 관리 가이드',
              sections: kPartyHelpSections,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: coordinator.goToCreate,
          ),
        ],
      ),
      body: MinglitAsyncValueWidget(
        value: partiesAsync,
        data: (entries) {
          if (entries.isEmpty) {
            return _PartyListEmptyState(onCreateTap: coordinator.goToCreate);
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(
              vertical: MinglitSpacing.medium,
            ),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
                child: PartyListItem(
                  entry: entry,
                  onTap: () => coordinator.goToDetail(entry.party.id),
                  onNextEventTap: entry.nextEvent != null
                      ? () => coordinator.goToEventDetail(
                          entry.party.id,
                          entry.nextEvent!.id,
                        )
                      : null,
                  onCreateEventTap: () =>
                      coordinator.goToCreateEvent(entry.party.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _PartyListEmptyState extends StatelessWidget {
  const _PartyListEmptyState({required this.onCreateTap});

  final VoidCallback onCreateTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: MinglitSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration_outlined,
              // Fix #2423/#2422: full-page empty states use canonical hero icon size token.
              size: MinglitIconSize.hero,
              color: theme.colorScheme.outlineVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              context.l10n.partyList_empty_title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.xsmall),
            Text(
              context.l10n.partyList_empty_subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.large),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add),
                label: Text(context.l10n.partyList_empty_createParty),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => showMinglitHelpSheet(
                  context: context,
                  title: context.l10n.partyList_helpSheet_title,
                  sections: [
                    HelpSection(
                      leading: const Icon(Icons.celebration_outlined),
                      title: context.l10n.partyList_helpSheet_q1_title,
                      body: context.l10n.partyList_helpSheet_q1_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.event_outlined),
                      title: context.l10n.partyList_helpSheet_q2_title,
                      body: context.l10n.partyList_helpSheet_q2_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.save_outlined),
                      title: context.l10n.partyList_helpSheet_q3_title,
                      body: context.l10n.partyList_helpSheet_q3_body,
                    ),
                    HelpSection(
                      leading: const Icon(Icons.people_outline),
                      title: context.l10n.partyList_helpSheet_q4_title,
                      body: context.l10n.partyList_helpSheet_q4_body,
                    ),
                  ],
                ),
                icon: const Icon(Icons.help_outline),
                label: Text(context.l10n.partyList_empty_helpButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
