import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/features/party/event/widgets/ticket_list_item.dart';
// Fix #2145: moved to logic/ — eliminates cross-feature application ↔ party/event dependency
import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/utils/l10n_ext.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailPage extends ConsumerWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(eventDetailProvider(eventId));
    final ticketsAsync = ref.watch(eventTicketsProvider(eventId));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.eventDetail_title)),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        data: (event) {
          final partyAsync = ref.watch(partyDetailProvider(event.partyId));
          final entryGroups = partyAsync.asData?.value.entryGroups ?? [];

          return _EventHubBody(
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

class _EventHubBody extends ConsumerWidget {
  const _EventHubBody({
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
    final applicationsAsync = ref.watch(eventApplicationsProvider(event.id));
    final applications =
        applicationsAsync.asData?.value ?? const <EventApplication>[];
    // Fix #2109: 확정/대기/환불 집계를 단일 허브 카드에서 일관되게 계산한다.
    final confirmedCount = applications
        .where((app) => app.status == 'approved' || app.status == 'paid')
        .length;
    final pendingCount = applications
        .where((app) => app.status == 'pending_review')
        .length;
    final refundedCount = applications
        .where((app) => app.status == 'cancelled' || app.status == 'refunded')
        .length;
    final location = event.party?.location ?? event.location;
    final totalRevenue =
        ticketsAsync.asData?.value.fold<int>(0, (sum, ticket) {
          final ticketConfirmedCount = applications
              .where(
                (app) =>
                    app.ticketId == ticket.id &&
                    (app.status == 'approved' || app.status == 'paid'),
              )
              .length;
          return sum + (ticket.price * ticketConfirmedCount);
        }) ??
        0;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        top: MinglitSpacing.small,
        bottom: MinglitSpacing.large,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (event.status == 'cancelled')
            _StatusBanner(
              backgroundColor: colorScheme.errorContainer,
              foregroundColor: colorScheme.onErrorContainer,
              icon: Icons.warning_amber_rounded,
              message: '이벤트가 취소되었습니다. 참가자에게 자동 환불 처리됩니다.',
            ),
          if (event.status == 'completed')
            _StatusBanner(
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              icon: Icons.celebration_outlined,
              message: '이벤트가 완료되었습니다. 🎊',
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: Text(
              event.title ?? context.l10n.eventDetail_title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.screenEdge,
              MinglitSpacing.small,
              MinglitSpacing.screenEdge,
              0,
            ),
            child: Wrap(
              spacing: MinglitSpacing.xsmall,
              runSpacing: MinglitSpacing.xsmall,
              children: [
                // Fix #2109: 운영 상태를 스펙의 chip 계층으로 승격한다.
                _MetaChip(
                  label: _statusLabel(event.status),
                  backgroundColor: _statusChipColor(colorScheme, event.status),
                  foregroundColor: _statusChipForegroundColor(
                    colorScheme,
                    event.status,
                  ),
                ),
                _MetaChip(
                  label: _visibilityLabel(event.effectiveVisibility),
                  backgroundColor: _visibilityChipColor(
                    colorScheme,
                    event.effectiveVisibility,
                  ),
                  foregroundColor: _visibilityChipForegroundColor(
                    colorScheme,
                    event.effectiveVisibility,
                  ),
                  icon: event.effectiveVisibility == 'private'
                      ? Icons.lock_outline
                      : Icons.public,
                  onTap: () {
                    // Fix #2109: 공개/비공개 chip 탭 시 노출 정책을 즉시 설명한다.
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          event.effectiveVisibility == 'private'
                              ? '비공개 이벤트입니다. 직접 공유한 링크로만 접근할 수 있습니다.'
                              : '공개 이벤트입니다. 파티 탐색과 공유 링크에서 노출됩니다.',
                        ),
                      ),
                    );
                  },
                ),
                _MetaChip(
                  label: _buildDdayLabel(event.startTime),
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.screenEdge,
              MinglitSpacing.small,
              MinglitSpacing.screenEdge,
              0,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _handleEditPressed(
                  context,
                  confirmedCount: confirmedCount,
                ),
                child: const Text('정보 수정'),
              ),
            ),
          ),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: '일정',
                  primary: _formatDateRange(event.startTime, event.endTime),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                _InfoRow(
                  icon: Icons.place_outlined,
                  label: '장소',
                  primary: location?.name ?? '장소 정보 없음',
                  secondary: _buildLocationAddress(location),
                ),
                if ((location?.directionsGuide ?? '').isNotEmpty) ...[
                  const SizedBox(height: MinglitSpacing.small),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: MinglitSpacing.large + MinglitSpacing.small,
                    ),
                    child: Text(
                      location!.directionsGuide!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: MinglitSpacing.medium),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: _canLaunchDirections(location)
                        ? () => unawaited(_launchDirections(location!))
                        : null,
                    icon: const Icon(
                      Icons.directions_outlined,
                      size: MinglitIconSize.small,
                    ),
                    label: const Text('길 안내'),
                  ),
                ),
              ],
            ),
          ),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '참가 현황',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Row(
                  children: [
                    Expanded(
                      child: _MetricBlock(
                        label: '확정',
                        value: '$confirmedCount',
                        tone: theme.colorScheme.primary,
                        valueStyle: theme.textTheme.headlineMedium,
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        label: '심사 대기',
                        value: '$pendingCount',
                        tone: colorScheme.onSurface,
                        valueStyle: theme.textTheme.headlineSmall,
                      ),
                    ),
                    Expanded(
                      child: _MetricBlock(
                        label: '환불',
                        value: '$refundedCount',
                        tone: colorScheme.secondary,
                        valueStyle: theme.textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: MinglitSpacing.medium),
                _InlineCapacityBar(
                  filled: confirmedCount,
                  total: event.maxParticipants,
                ),
                const SizedBox(height: MinglitSpacing.xsmall),
                Text(
                  '$confirmedCount / ${event.maxParticipants}명',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: MinglitSpacing.medium),
                if (pendingCount >= 1) ...[
                  FilledButton(
                    onPressed: () => _openApplicationList(context),
                    child: const Text('심사하기'),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                ],
                OutlinedButton(
                  onPressed: () => _openApplicationList(context),
                  child: const Text('참가자 보기'),
                ),
              ],
            ),
          ),
          if ((ticketsAsync.asData?.value ?? const <Ticket>[]).isNotEmpty)
            _SectionCard(
              child: Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: MinglitIconSize.small,
                    color: colorScheme.secondary,
                  ),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Text(
                      '예상 매출: ${NumberFormat.currency(locale: 'ko_KR', symbol: '₩', decimalDigits: 0).format(totalRevenue)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
              error: (e, s) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: Text(
                  context.l10n.partyDetail_error_ticketLoad(e.toString()),
                ),
              ),
            ),
          ),
          if (entryGroups.isNotEmpty)
            MinglitSection(
              title: '입장 그룹별 현황',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _SectionCard(
                  margin: EdgeInsets.zero,
                  child: Column(
                    children: entryGroups
                        .map(
                          (group) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.group_outlined),
                            title: Text(
                              group.label ??
                                  '그룹 ${entryGroups.indexOf(group) + 1}',
                            ),
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
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildGroupSubtitle(PartyEntryGroup group) {
    final parts = <String>[];
    if (group.gender != null) {
      parts.add(
        group.gender == 'male'
            ? '남성'
            : group.gender == 'female'
            ? '여성'
            : group.gender!,
      );
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

  void _openApplicationList(BuildContext context) {
    unawaited(
      EventApplicationListRoute(
        partyId: event.partyId,
        eventId: event.id,
      ).push<void>(context),
    );
  }

  void _handleEditPressed(
    BuildContext context, {
    required int confirmedCount,
  }) {
    // Fix #2109: 참가 확정 인원이 있으면 운영 정보 수정 진입을 잠근다.
    if (confirmedCount >= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('참가 확정 이후에는 정보 수정을 할 수 없습니다.'),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이벤트 정보 수정 기능은 준비 중입니다.')),
    );
  }

  bool _canLaunchDirections(Location? location) {
    if (location == null) return false;
    return location.latitude != 0 && location.longitude != 0;
  }

  Future<void> _launchDirections(Location location) async {
    // Fix #2109: 좌표가 있을 때만 외부 길 안내 링크를 연다.
    final uri = Uri.parse(
      'https://map.kakao.com/link/map/${location.latitude},${location.longitude}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.icon,
    required this.message,
  });

  final Color backgroundColor;
  final Color foregroundColor;
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.screenEdge,
        0,
        MinglitSpacing.screenEdge,
        MinglitSpacing.small,
      ),
      child: Container(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: MinglitIconSize.small, color: foregroundColor),
            const SizedBox(width: MinglitSpacing.small),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: foregroundColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.child,
    this.margin = const EdgeInsets.fromLTRB(
      MinglitSpacing.screenEdge,
      MinglitSpacing.medium,
      MinglitSpacing.screenEdge,
      0,
    ),
  });

  final Widget child;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: MinglitIconSize.xsmall, color: foregroundColor),
            const SizedBox(width: MinglitSpacing.xxsmall),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foregroundColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: child,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.primary,
    this.secondary,
  });

  final IconData icon;
  final String label;
  final String primary;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: MinglitIconSize.small,
          color: colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xxsmall),
              Text(
                primary,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if ((secondary ?? '').isNotEmpty) ...[
                const SizedBox(height: MinglitSpacing.xxsmall),
                Text(
                  secondary!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.tone,
    required this.valueStyle,
  });

  final String label;
  final String value;
  final Color tone;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        Text(
          value,
          style: valueStyle?.copyWith(
            color: tone,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _InlineCapacityBar extends StatelessWidget {
  const _InlineCapacityBar({required this.filled, required this.total});

  final int filled;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = total <= 0 ? 0.0 : (filled / total).clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(MinglitRadius.small),
      child: LinearProgressIndicator(
        value: ratio,
        minHeight: 10,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'cancelled':
      return '취소됨';
    case 'completed':
      return '완료됨';
    case 'scheduled':
    default:
      return '모집중';
  }
}

Color _statusChipColor(ColorScheme colorScheme, String status) {
  switch (status) {
    case 'cancelled':
      return colorScheme.errorContainer;
    case 'completed':
      return colorScheme.surfaceContainerHighest;
    case 'scheduled':
    default:
      return colorScheme.primaryContainer;
  }
}

Color _statusChipForegroundColor(ColorScheme colorScheme, String status) {
  switch (status) {
    case 'cancelled':
      return colorScheme.onErrorContainer;
    case 'completed':
      return colorScheme.onSurfaceVariant;
    case 'scheduled':
    default:
      return colorScheme.onPrimaryContainer;
  }
}

String _visibilityLabel(String visibility) {
  switch (visibility) {
    case 'private':
      return '비공개';
    case 'public':
      return '공개';
    default:
      return '파티 설정';
  }
}

Color _visibilityChipColor(ColorScheme colorScheme, String visibility) {
  if (visibility == 'private') {
    return colorScheme.surfaceContainerHighest;
  }
  return colorScheme.secondaryContainer;
}

Color _visibilityChipForegroundColor(
  ColorScheme colorScheme,
  String visibility,
) {
  if (visibility == 'private') {
    return colorScheme.onSurfaceVariant;
  }
  return colorScheme.onSecondaryContainer;
}

String _buildDdayLabel(DateTime startTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(startTime.year, startTime.month, startTime.day);
  final diff = target.difference(today).inDays;

  // Fix #2109: D-day 계산을 날짜 단위로 고정해 시간대 오차를 제거한다.
  if (diff == 0) return 'D-Day';
  if (diff > 0) return 'D-$diff';
  return 'D+${diff.abs()}';
}

String _formatDateRange(DateTime startTime, DateTime endTime) {
  final dateFormat = DateFormat('yyyy년 M월 d일 (E) HH:mm', 'ko');
  final timeFormat = DateFormat('HH:mm', 'ko');
  return '${dateFormat.format(startTime)} ~ ${timeFormat.format(endTime)}';
}

String _buildLocationAddress(Location? location) {
  if (location == null) return '주소 정보 없음';

  final parts = <String>[location.address];
  if ((location.addressDetail ?? '').isNotEmpty) {
    parts.add(location.addressDetail!);
  }
  return parts.join(' ');
}
