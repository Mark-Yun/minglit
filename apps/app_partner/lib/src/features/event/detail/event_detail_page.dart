import 'dart:async';

import 'package:app_partner/src/features/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/event/widgets/ticket_list_item.dart';
import 'package:app_partner/src/routing/app_routes.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('회차 상세')),
      body: eventAsync.when(
        data: (event) {
          final dateFormat = DateFormat('yyyy년 MM월 dd일 (E)', 'ko');
          final timeFormat = DateFormat('a h:mm', 'ko');

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
                        label: '일시',
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
                        label: '시간',
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
                        label: '정원',
                        value:
                            '${event.currentParticipants} / ${event.maxParticipants}명',
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: MinglitSpacing.small,
                        ),
                        child: Divider(height: 1),
                      ),
                      _DetailRow(
                        icon: Icons.info_outline,
                        label: '상태',
                        value: _getStatusLabel(event.status),
                        valueColor: _getStatusColor(event.status, colorScheme),
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
                      '티켓 관리',
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
                      label: const Text('티켓 만들기'),
                    ),
                  ],
                ),
                const SizedBox(height: MinglitSpacing.small),

                ticketsAsync.when(
                  data: (tickets) => TicketListView(
                    tickets: tickets,

                    onCreatePressed: () {
                      unawaited(
                        TicketCreateRoute(
                          partyId: event.partyId,

                          eventId: event.id,
                        ).push<void>(context),
                      );
                    },

                    onTicketTap: (ticket) {
                      // TODO(mark): Implement Ticket Detail or Edit
                    },
                  ),

                  loading: () =>
                      const Center(child: CircularProgressIndicator()),

                  error: (e, s) => Text('티켓 로드 실패: $e'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('로드 실패: $e')),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'scheduled':
        return '모집 예정/진행중';
      case 'cancelled':
        return '취소됨';
      case 'completed':
        return '종료됨';
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
