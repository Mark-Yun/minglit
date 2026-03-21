import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/event_application_list_view.dart';
import 'package:app_partner/src/features/party/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final ticketsAsync = ref.watch(eventTicketsProvider(eventId));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.eventDetail_title),
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.partyDetail_tab_operation),
              const Tab(text: '참가 신청'),
            ],
          ),
        ),
        body: MinglitAsyncValueWidget(
          value: eventAsync,
          data: (event) {
            final partyAsync = ref.watch(partyDetailProvider(event.partyId));
            final entryGroups = partyAsync.asData?.value.entryGroups ?? [];

            return TabBarView(
              children: [
                // Tab 1: 운영 관리
                _EventInfoTab(
                  event: event,
                  ticketsAsync: ticketsAsync,
                  entryGroups: entryGroups,
                ),
                // Tab 2: 참가 신청
                EventApplicationListView(eventId: event.id),
              ],
            );
          },
          error: (e, s) => Center(
            child: Text(context.l10n.partyList_error_load(e.toString())),
          ),
        ),
      ),
    );
  }
}

class _EventInfoTab extends ConsumerWidget {
  const _EventInfoTab({
    required this.event,
    required this.ticketsAsync,
    required this.entryGroups,
  });

  final Event event;
  final AsyncValue<List<Ticket>> ticketsAsync;
  final List<PartyEntryGroup> entryGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
    final timeFormat = DateFormat('a h:mm', 'ko');

    // Watch applications to show count
    final appsAsync = ref.watch(eventApplicationsProvider(event.id));
    final appCount = appsAsync.asData?.value.length ?? 0;
    final pendingCount =
        appsAsync.asData?.value
            .where((a) => a.status == 'pending_review')
            .length ??
        0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.title != null) ...[
            Text(
              event.title!,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: MinglitSpacing.large),
          ],
          Container(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: context.l10n.eventDetail_label_dateTime,
                  value: dateFormat.format(event.startTime),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: MinglitSpacing.small,
                  ),
                  child: Divider(height: 1),
                ),
                _DetailRow(
                  icon: Icons.access_time,
                  label: context.l10n.eventDetail_label_time,
                  value:
                      '${timeFormat.format(event.startTime)} ~ '
                      '${timeFormat.format(event.endTime)}',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: MinglitSpacing.small,
                  ),
                  child: Divider(height: 1),
                ),
                _DetailRow(
                  icon: Icons.people_outline,
                  label: '참가 현황', // Changed label
                  value:
                      '확정 ${event.currentParticipants}명 / 신청 $appCount명 (대기 $pendingCount)',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: MinglitSpacing.small,
                  ),
                  child: Divider(height: 1),
                ),
                _DetailRow(
                  icon: Icons.info_outline,
                  label: context.l10n.eventDetail_label_status,
                  value: _getStatusLabel(context, event.status),
                  valueColor: _getStatusColor(event.status, colorScheme),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: MinglitSpacing.small,
                  ),
                  child: Divider(height: 1),
                ),
                _DetailRow(
                  icon: Icons.visibility,
                  label: '공개 설정',
                  value: _getVisibilityLabel(event.visibility),
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Tickets Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.l10n.eventDetail_section_ticketManage,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  unawaited(
                    TicketCreateRoute(
                      partyId: event.partyId,
                      eventId: event.id,
                    ).push<void>(context),
                  );
                },
                icon: const Icon(Icons.add, size: MinglitIconSize.small),
                label: Text(context.l10n.eventDetail_button_createTicket),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.small),

          MinglitAsyncValueWidget(
            value: ticketsAsync,
            data: (tickets) => TicketListView(
              tickets: tickets,
              entryGroups: entryGroups,
              maxParticipants: event.maxParticipants,
              onCreatePressed: () {
                unawaited(
                  TicketCreateRoute(
                    partyId: event.partyId,
                    eventId: event.id,
                  ).push<void>(context),
                );
              },
              onTicketTap: (ticket) {
                unawaited(
                  TicketEditRoute(
                    partyId: event.partyId,
                    eventId: event.id,
                    ticketId: ticket.id,
                  ).push<void>(context),
                );
              },
            ),
            error: (e, s) => Text(
              context.l10n.partyDetail_error_ticketLoad(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusLabel(BuildContext context, String status) {
    switch (status) {
      case 'scheduled':
        return context.l10n.eventDetail_status_scheduled;
      case 'cancelled':
        return context.l10n.eventDetail_status_cancelled;
      case 'completed':
        return context.l10n.eventDetail_status_completed;
      default:
        return status;
    }
  }

  Color? _getStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'scheduled':
        return colorScheme.primary;
      case 'cancelled':
        return colorScheme.error;
      case 'completed':
        return colorScheme.outline;
      default:
        return null;
    }
  }

  String _getVisibilityLabel(String? visibility) {
    if (visibility == 'private') {
      return '비공개';
    } else if (visibility == 'public') {
      return '공개';
    } else {
      return '파티 설정 따라가기';
    }
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(
          icon,
          size: MinglitIconSize.small,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: MinglitSpacing.small),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: valueColor,
            fontWeight: valueColor != null ? FontWeight.bold : null,
          ),
        ),
      ],
    );
  }
}
