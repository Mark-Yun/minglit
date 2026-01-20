import 'package:app_partner/src/features/party/detail/party_detail_coordinator.dart';
import 'package:app_partner/src/features/party/widgets/party_event_list_summary.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyEventManagementTab extends ConsumerWidget {
  const PartyEventManagementTab({required this.party, super.key});

  final Party party;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(partyEventsProvider(party.id));
    final coordinator = ref.read(partyDetailCoordinatorProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Events Section
          Text(
            context.l10n.partyDetail_section_events,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: MinglitSpacing.small),
          MinglitAsyncValueWidget(
            value: eventsAsync,
            data: (events) => PartyEventListSummary(
              events: events,
              onEventTap: (event) =>
                  coordinator.goToEventDetail(party.id, event.id),
              onCreatePressed: () => coordinator.goToCreateEvent(party.id),
            ),
            error: (e, s) =>
                Text(context.l10n.partyDetail_error_eventLoad(e.toString())),
          ),
        ],
      ),
    );
  }
}
