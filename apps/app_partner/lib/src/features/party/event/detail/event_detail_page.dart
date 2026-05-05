import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_application_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

// Fix #2224: Tab 구조 폐기 — 단일 스크롤 페이지로 변경, AppBar 타이틀 수정,
// 참가 신청은 EventApplicationListRoute로 분리.
class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final ticketsAsync = ref.watch(eventTicketsProvider(eventId));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.eventDetail_title),
      ),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) {
          final partyAsync = ref.watch(partyDetailProvider(event.partyId));
          final entryGroups = partyAsync.asData?.value.entryGroups ?? [];

          return _EventInfoTab(
            event: event,
            ticketsAsync: ticketsAsync,
            entryGroups: entryGroups,
          );
        },
        error: (e, s) => Center(
          child: Text(context.l10n.partyList_error_load(e.toString())),
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

    final appsAsync = ref.watch(eventApplicationsProvider(event.id));
    final applications = appsAsync.asData?.value ?? [];
    final appCount = applications.length;
    final pendingCount = applications
        .where((a) => a.status == 'pending_review')
        .length;
    // Fix #2224: canonical source for confirmed participants is event.currentParticipants,
    // not the application list count — application list may be paginated/incomplete.
    final confirmedCount = event.currentParticipants;
    final maxParticipants = event.maxParticipants;

    return SingleChildScrollView(
      child: MinglitContentLayout(
        sections: [
          // Event title
          if (event.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.screenEdge,
              ),
              child: Text(
                event.title!,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),

          // Schedule + status info card
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: Container(
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
          ),

          // 참가 현황 section
          MinglitSection(
            title: '참가 현황',
            trailing: TextButton.icon(
              onPressed: () {
                unawaited(
                  EventApplicationListRoute(
                    partyId: event.partyId,
                    eventId: event.id,
                  ).push<void>(context),
                );
              },
              icon: const Icon(
                Icons.people_outline,
                size: MinglitIconSize.small,
              ),
              label: const Text('신청 목록 보기'),
            ),
            padding: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.screenEdge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$confirmedCount',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      if (maxParticipants > 0)
                        Text(
                          ' / $maxParticipants 명',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const Spacer(),
                      if (pendingCount > 0)
                        Flexible(
                          child: Text(
                            '신청 $appCount명 (대기 $pendingCount건)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  if (maxParticipants > 0)
                    MinglitCapacityBar(
                      total: maxParticipants,
                      filled: confirmedCount,
                      pending: pendingCount,
                    ),
                  if (pendingCount > 0) ...[
                    const SizedBox(height: MinglitSpacing.small),
                    InkWell(
                      onTap: () {
                        unawaited(
                          EventApplicationListRoute(
                            partyId: event.partyId,
                            eventId: event.id,
                          ).push<void>(context),
                        );
                      },
                      child: Text(
                        '심사 대기 $pendingCount건 처리하기 →',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tickets Section
          MinglitSection(
            title: context.l10n.eventDetail_section_ticketManage,
            trailing: TextButton.icon(
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
            padding: EdgeInsets.zero,
            child: MinglitAsyncValueWidget(
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
          ),

          // 입장 그룹별 현황 section
          if (entryGroups.isNotEmpty)
            MinglitSection(
              title: '입장 그룹별 현황',
              padding: EdgeInsets.zero,
              child: Column(
                children: entryGroups
                    .map(
                      (group) => ListTile(
                        leading: const Icon(Icons.group_outlined),
                        title: Text(group.label ?? '그룹 ${entryGroups.indexOf(group) + 1}'),
                        subtitle: _buildGroupSubtitle(group),
                        trailing: const Icon(
                          Icons.chevron_right,
                          size: MinglitIconSize.small,
                        ),
                        onTap: () {
                          unawaited(
                            EventApplicationListRoute(
                              partyId: event.partyId,
                              eventId: event.id,
                              groupId: group.id,
                            ).push<void>(context),
                          );
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildGroupSubtitle(PartyEntryGroup group) {
    final parts = <String>[];
    if (group.gender != null) {
      parts.add(group.gender == 'male' ? '남성' : group.gender == 'female' ? '여성' : group.gender!);
    }
    if (group.birthYearMin != null && group.birthYearMax != null) {
      parts.add('${group.birthYearMin}~${group.birthYearMax}년생');
    } else if (group.birthYearMin != null) {
      parts.add('${group.birthYearMin}년생 이후');
    } else if (group.birthYearMax != null) {
      parts.add('${group.birthYearMax}년생 이전');
    }
    if (parts.isEmpty) return null;
    return Text(parts.join(' · '));
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: MinglitIconSize.small,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: MinglitSpacing.small),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: valueColor,
              fontWeight: valueColor != null ? FontWeight.bold : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
