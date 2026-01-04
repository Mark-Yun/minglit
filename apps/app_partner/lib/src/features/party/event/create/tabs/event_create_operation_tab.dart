import 'package:app_partner/src/features/party/event/create/event_create_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/event_date_time_input.dart';
import 'package:app_partner/src/features/party/ticket/widgets/party_tickets_summary.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventCreateOperationTab extends StatelessWidget {
  const EventCreateOperationTab({
    required this.state,
    required this.notifier,
    super.key,
  });

  final EventCreateState state;
  final EventCreateController notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: _buildSectionHeader(context, '일정 설정'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: EventDateTimeInput(
              startTime: state.startTime,
              endTime: state.endTime,
              onStartTimeChanged: notifier.updateStartTime,
              onEndTimeChanged: notifier.updateEndTime,
            ),
          ),
          const SizedBox(height: MinglitSpacing.large),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: _buildSectionHeader(context, '티켓 판매 현황'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: PartyTicketsSummary(
              tickets: state.tickets,
              entryGroups: state.entryGroups,
              maxCapacity: state.maxParticipants,
              showStats: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
