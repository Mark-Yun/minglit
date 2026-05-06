import 'dart:async';

import 'package:app_partner/src/features/party/detail/party_detail_controller.dart';
import 'package:app_partner/src/features/party/event/detail/event_detail_controller.dart';
import 'package:app_partner/src/logic/event_application_logic.dart';
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

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(context.l10n.eventDetail_title),
        actions: [
          IconButton(
            tooltip: '화면 정보',
            onPressed: () {
              context.showMinglitInfo('이벤트 운영 상태와 신청 현황을 한 화면에서 확인할 수 있어요.');
            },
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      body: MinglitAsyncValueWidget(
        value: eventAsync,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          onRetry: () {
            ref.invalidate(eventDetailProvider(eventId));
            ref.invalidate(eventApplicationsProvider(eventId));
            ref.invalidate(eventTicketsProvider(eventId));
          },
        ),
        data: (event) {
          final partyAsync = ref.watch(partyDetailProvider(event.partyId));
          final applicationsAsync = ref.watch(
            eventApplicationsProvider(event.id),
          );
          final ticketsAsync = ref.watch(eventTicketsProvider(event.id));

          // Fix #2275: ticketsAsync loading/error must be gated the same way as
          // partyAsync/applicationsAsync — but allow fallback to event.tickets
          // when it is already populated (eager-loaded with the event fetch).
          final hasFallbackTickets =
              (event.tickets ?? const <Ticket>[]).isNotEmpty;
          if (partyAsync.isLoading ||
              applicationsAsync.isLoading ||
              (ticketsAsync.isLoading && !hasFallbackTickets)) {
            return const Center(child: CircularProgressIndicator());
          }

          if (partyAsync.hasError ||
              applicationsAsync.hasError ||
              (ticketsAsync.hasError && !hasFallbackTickets)) {
            return _ErrorView(
              onRetry: () {
                ref.invalidate(eventDetailProvider(eventId));
                ref.invalidate(partyDetailProvider(event.partyId));
                ref.invalidate(eventApplicationsProvider(event.id));
                ref.invalidate(eventTicketsProvider(event.id));
              },
            );
          }

          final party = partyAsync.requireValue;
          final applications = applicationsAsync.requireValue;
          final tickets =
              ticketsAsync.asData?.value ?? event.tickets ?? const <Ticket>[];
          final entryGroups =
              event.entryGroups ??
              party.entryGroups
                  ?.map(
                    (group) => EntryGroup(
                      id: group.id,
                      eventId: event.id,
                      label: group.label,
                      gender: group.gender,
                      birthYearMin: group.birthYearMin,
                      birthYearMax: group.birthYearMax,
                      requiredVerificationIds: group.requiredVerificationIds,
                      createdAt: group.createdAt,
                      updatedAt: group.updatedAt,
                    ),
                  )
                  .toList() ??
              const <EntryGroup>[];

          return _EventDetailBody(
            event: event,
            party: party,
            applications: applications,
            tickets: tickets,
            entryGroups: entryGroups,
          );
        },
      ),
    );
  }
}

class _EventDetailBody extends ConsumerWidget {
  const _EventDetailBody({
    required this.event,
    required this.party,
    required this.applications,
    required this.tickets,
    required this.entryGroups,
  });

  final Event event;
  final Party party;
  final List<EventApplication> applications;
  final List<Ticket> tickets;
  final List<EntryGroup> entryGroups;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = _EventPageSummary.fromData(
      event: event,
      tickets: tickets,
      applications: applications,
      entryGroups: entryGroups,
    );
    final state = _EventLifecycleState.from(
      event: event,
      applications: applications,
    );

    return SingleChildScrollView(
      child: MinglitContentLayout(
        sections: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.screenEdge,
              MinglitSpacing.medium,
              MinglitSpacing.screenEdge,
              0,
            ),
            child: Text(
              event.title ?? party.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
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
                _VisibilityChip(visibility: event.effectiveVisibility),
                _StatusChip(status: event.status),
                _EventDDayChip(event: event, state: state),
              ],
            ),
          ),
          if (state == _EventLifecycleState.cancelled)
            _InlineBanner(
              icon: Icons.warning_amber_rounded,
              message: '이 이벤트는 취소되었고, 결제 사용자 환불 현황을 운영 기준으로 확인할 수 있어요.',
              isError: true,
            ),
          if (state == _EventLifecycleState.completed)
            _CelebrateBanner(participantCount: summary.confirmedCount),
          // Fix #2275: spec #2109 — lock editing when confirmed participants ≥1
          if (state.isEditable && summary.confirmedCount == 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                MinglitSpacing.screenEdge,
                MinglitSpacing.small,
                MinglitSpacing.screenEdge,
                0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  onTap: () {
                    // Fix #2109: EventEditRoute is not available in this branch yet.
                    // Keep the hub affordance and surface temporary guidance instead
                    // of wiring a broken route.
                    context.showMinglitInfo('이벤트 정보 수정 연결은 다음 작업에서 이어집니다.');
                  },
                  borderRadius: BorderRadius.circular(MinglitRadius.small),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MinglitSpacing.xsmall,
                      vertical: MinglitSpacing.xxsmall,
                    ),
                    child: Text(
                      '정보 수정',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.screenEdge,
            ),
            child: _HeroCard(
              event: event,
              party: party,
              isCancelled: state == _EventLifecycleState.cancelled,
            ),
          ),
          if (state == _EventLifecycleState.cancelled)
            MinglitSection(
              title: '환불 완료',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _RefundCard(summary: summary),
              ),
            )
          else
            MinglitSection(
              title: '참가 현황',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _ParticipationCard(
                  event: event,
                  summary: summary,
                  showReviewAction: state.canReviewApplications,
                ),
              ),
            ),
          // Fix #2275: cancelled 상태에서 _RefundCard와 타이틀 중복 방지 — 매출 섹션 숨김
          if (state != _EventLifecycleState.cancelled)
            MinglitSection(
              title: state.revenueTitle,
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _RevenueCard(
                  state: state,
                  summary: summary,
                ),
              ),
            ),
          if (state == _EventLifecycleState.completed)
            MinglitSection(
              title: '완료 통계',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _CompletedStatsCard(summary: summary),
              ),
            ),
          if (entryGroups.isNotEmpty)
            MinglitSection(
              title: state == _EventLifecycleState.cancelled
                  ? '입장 그룹별 환불 정보'
                  : '입장 그룹별 현황',
              padding: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.screenEdge,
                ),
                child: _EntryGroupBreakdown(
                  event: event,
                  state: state,
                  summary: summary,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

enum _EventLifecycleState {
  scheduled,
  cancelled,
  completed,
  emptyApplications
  ;

  factory _EventLifecycleState.from({
    required Event event,
    required List<EventApplication> applications,
  }) {
    if (event.status == 'cancelled') {
      return _EventLifecycleState.cancelled;
    }
    if (event.status == 'completed') {
      return _EventLifecycleState.completed;
    }
    if (applications.isEmpty) {
      return _EventLifecycleState.emptyApplications;
    }
    return _EventLifecycleState.scheduled;
  }

  bool get isEditable =>
      this == _EventLifecycleState.scheduled ||
      this == _EventLifecycleState.emptyApplications;

  bool get canReviewApplications => this == _EventLifecycleState.scheduled;

  String get revenueTitle {
    switch (this) {
      case _EventLifecycleState.cancelled:
        return '환불 완료';
      case _EventLifecycleState.completed:
        return '달성 매출';
      case _EventLifecycleState.scheduled:
      case _EventLifecycleState.emptyApplications:
        return '기대 매출';
    }
  }
}

class _EventPageSummary {
  const _EventPageSummary({
    required this.confirmedCount,
    required this.pendingCount,
    required this.refundedCount,
    required this.currentRevenue,
    required this.pendingRevenue,
    required this.maxRevenue,
    required this.refundAmount,
    required this.groupSummaries,
  });

  final int confirmedCount;
  final int pendingCount;
  final int refundedCount;
  final int currentRevenue;
  final int pendingRevenue;
  final int maxRevenue;
  final int refundAmount;
  final List<_EntryGroupSummary> groupSummaries;

  factory _EventPageSummary.fromData({
    required Event event,
    required List<Ticket> tickets,
    required List<EventApplication> applications,
    required List<EntryGroup> entryGroups,
  }) {
    final pendingCount = applications
        .where((app) => app.status == 'pending_review')
        .length;
    final refundedApps = applications
        .where((app) => app.refundStatus == 'completed')
        .toList();
    final refundedCount = refundedApps.length;
    final refundAmount = refundedApps.fold<int>(
      0,
      (sum, app) => sum + (app.paymentAmount ?? app.ticket?.price ?? 0),
    );

    final ticketById = {for (final ticket in tickets) ticket.id: ticket};
    final currentRevenue = applications
        .where(
          (app) =>
              app.status != 'pending_review' && app.refundStatus != 'completed',
        )
        .fold<int>(
          0,
          (sum, app) =>
              sum + (app.paymentAmount ?? ticketById[app.ticketId]?.price ?? 0),
        );
    final pendingRevenue = applications
        .where(
          (app) =>
              app.status == 'pending_review' && app.refundStatus != 'completed',
        )
        .fold<int>(
          0,
          (sum, app) =>
              sum + (app.paymentAmount ?? ticketById[app.ticketId]?.price ?? 0),
        );
    final maxRevenue = tickets.fold<int>(
      0,
      (sum, ticket) => sum + (ticket.price * ticket.quantity),
    );

    final groupSummaries = entryGroups
        .map(
          (group) => _EntryGroupSummary.fromData(
            group: group,
            tickets: tickets,
            applications: applications,
          ),
        )
        .toList();

    return _EventPageSummary(
      confirmedCount: event.currentParticipants,
      pendingCount: pendingCount,
      refundedCount: refundedCount,
      currentRevenue: currentRevenue,
      pendingRevenue: pendingRevenue,
      maxRevenue: maxRevenue,
      refundAmount: refundAmount,
      groupSummaries: groupSummaries,
    );
  }
}

class _EntryGroupSummary {
  const _EntryGroupSummary({
    required this.group,
    required this.confirmedCount,
    required this.pendingCount,
    required this.refundedCount,
    required this.currentRevenue,
    required this.pendingRevenue,
    required this.maxRevenue,
  });

  final EntryGroup group;
  final int confirmedCount;
  final int pendingCount;
  final int refundedCount;
  final int currentRevenue;
  final int pendingRevenue;
  final int maxRevenue;

  factory _EntryGroupSummary.fromData({
    required EntryGroup group,
    required List<Ticket> tickets,
    required List<EventApplication> applications,
  }) {
    final groupTickets = tickets
        .where((ticket) => ticket.targetEntryGroupIds.contains(group.id))
        .toList();
    final groupTicketIds = groupTickets.map((ticket) => ticket.id).toSet();
    final groupApplications = applications
        .where((app) => groupTicketIds.contains(app.ticketId))
        .toList();

    final confirmedCount = groupApplications
        .where(
          (app) =>
              app.status != 'pending_review' && app.refundStatus != 'completed',
        )
        .length;
    final pendingCount = groupApplications
        .where((app) => app.status == 'pending_review')
        .length;
    final refundedCount = groupApplications
        .where((app) => app.refundStatus == 'completed')
        .length;
    final currentRevenue = groupApplications
        .where(
          (app) =>
              app.status != 'pending_review' && app.refundStatus != 'completed',
        )
        .fold<int>(
          0,
          (sum, app) => sum + (app.paymentAmount ?? app.ticket?.price ?? 0),
        );
    final pendingRevenue = groupApplications
        .where(
          (app) =>
              app.status == 'pending_review' && app.refundStatus != 'completed',
        )
        .fold<int>(
          0,
          (sum, app) => sum + (app.paymentAmount ?? app.ticket?.price ?? 0),
        );
    final maxRevenue = groupTickets.fold<int>(
      0,
      (sum, ticket) => sum + (ticket.price * ticket.quantity),
    );

    return _EntryGroupSummary(
      group: group,
      confirmedCount: confirmedCount,
      pendingCount: pendingCount,
      refundedCount: refundedCount,
      currentRevenue: currentRevenue,
      pendingRevenue: pendingRevenue,
      maxRevenue: maxRevenue,
    );
  }

  String get label => group.label ?? '입장 그룹';
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '이벤트를 불러오지 못했어요.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.small),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  const _InlineBanner({
    required this.icon,
    required this.message,
    this.isError = false,
  });

  final IconData icon;
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foregroundColor = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.screenEdge,
        MinglitSpacing.small,
        MinglitSpacing.screenEdge,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: MinglitIconSize.small, color: foregroundColor),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foregroundColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CelebrateBanner extends StatelessWidget {
  const _CelebrateBanner({required this.participantCount});

  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.screenEdge,
        MinglitSpacing.small,
        MinglitSpacing.screenEdge,
        0,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.small,
          ),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$participantCount명',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: '과 함께한 이벤트가 완료됐어요',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.event,
    required this.party,
    required this.isCancelled,
  });

  final Event event;
  final Party party;
  final bool isCancelled;

  @override
  Widget build(BuildContext context) {
    final location = event.location ?? party.location;
    final scheduleStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      decoration: isCancelled ? TextDecoration.lineThrough : null,
      color: isCancelled
          ? Theme.of(context).colorScheme.onSurfaceVariant
          : null,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoBlock(
              label: '일정',
              primary: _formatDate(event.startTime),
              secondary:
                  '${_formatTime(event.startTime)} ~ ${_formatTime(event.endTime)}',
              primaryStyle: scheduleStyle,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            _InfoBlock(
              label: '장소',
              primary: location?.name ?? '장소 미정',
              secondary:
                  [
                        location?.address,
                        location?.addressDetail,
                      ]
                      .whereType<String>()
                      .where((value) => value.isNotEmpty)
                      .join(' '),
            ),
            const SizedBox(height: MinglitSpacing.small),
            _MapPlaceholder(locationName: location?.name ?? '장소 미정'),
            if ((location?.directionsGuide ?? '').isNotEmpty) ...[
              const SizedBox(height: MinglitSpacing.small),
              _InfoBlock(
                label: '오시는길',
                primary: location!.directionsGuide!,
                primaryStyle: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) =>
      DateFormat('yyyy.MM.dd (E)', 'ko').format(value);

  String _formatTime(DateTime value) =>
      DateFormat('a h:mm', 'ko').format(value);
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({
    required this.label,
    required this.primary,
    this.secondary,
    this.primaryStyle,
  });

  final String label;
  final String primary;
  final String? secondary;
  final TextStyle? primaryStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        Text(
          primary,
          style:
              primaryStyle ??
              theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        if (secondary != null && secondary!.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.xxsmall),
          Text(
            secondary!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder({required this.locationName});

  final String locationName;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(MinglitRadius.input),
      ),
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: Text(
                  '$locationName 위치 보기',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParticipationCard extends StatelessWidget {
  const _ParticipationCard({
    required this.event,
    required this.summary,
    required this.showReviewAction,
  });

  final Event event;
  final _EventPageSummary summary;
  final bool showReviewAction;

  @override
  Widget build(BuildContext context) {
    final reviewLabel = '심사 대기 ${summary.pendingCount}건 처리하기';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${summary.confirmedCount}',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                ' / ${event.maxParticipants} ${event.status == 'completed' ? '참석' : '확정'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.small),
          MinglitCapacityBar(
            total: event.maxParticipants,
            filled: summary.confirmedCount,
            pending: summary.pendingCount,
          ),
          const SizedBox(height: MinglitSpacing.small),
          Wrap(
            spacing: MinglitSpacing.medium,
            runSpacing: MinglitSpacing.xsmall,
            children: [
              _MetricText(
                label: event.status == 'completed' ? '참석' : '확정',
                value: summary.confirmedCount,
              ),
              if (summary.pendingCount > 0)
                _MetricText(label: '심사대기', value: summary.pendingCount),
              if (summary.refundedCount > 0)
                _MetricText(label: '환불완료', value: summary.refundedCount),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),
          if (showReviewAction && summary.pendingCount > 0) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  unawaited(
                    EventApplicationListRoute(
                      partyId: event.partyId,
                      eventId: event.id,
                    ).push<void>(context),
                  );
                },
                child: Text(reviewLabel),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                unawaited(
                  EventApplicationListRoute(
                    partyId: event.partyId,
                    eventId: event.id,
                  ).push<void>(context),
                );
              },
              child: const Text('참가자 보기'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.summary});

  final _EventPageSummary summary;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _StackedMetric(
                  value: _formatCurrency(summary.refundAmount),
                  label: '환불액',
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: _StackedMetric(
                  value: '${summary.refundedCount}건',
                  label: '환불 완료',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({
    required this.state,
    required this.summary,
  });

  final _EventLifecycleState state;
  final _EventPageSummary summary;

  @override
  Widget build(BuildContext context) {
    final currentValue = state == _EventLifecycleState.cancelled
        ? summary.refundAmount
        : summary.currentRevenue;
    final pendingValue = state == _EventLifecycleState.scheduled
        ? summary.pendingRevenue
        : 0;
    final totalValue = state == _EventLifecycleState.cancelled
        ? (summary.refundAmount == 0 ? 1 : summary.refundAmount)
        : (summary.maxRevenue == 0 ? 1 : summary.maxRevenue);
    final groupTitle = state == _EventLifecycleState.completed
        ? '그룹별 객단가'
        : '그룹별 매출';

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(currentValue),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (state != _EventLifecycleState.cancelled) ...[
                const SizedBox(width: MinglitSpacing.xsmall),
                Expanded(
                  child: Text(
                    '/ 최대 ${_formatCurrency(summary.maxRevenue)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Fix #2275: capacity bar is meaningless in cancelled state (always 100%)
          if (state != _EventLifecycleState.cancelled) ...[
            const SizedBox(height: MinglitSpacing.small),
            MinglitCapacityBar(
              total: totalValue,
              filled: currentValue,
              pending: pendingValue,
            ),
          ],
          const SizedBox(height: MinglitSpacing.small),
          Text(
            state == _EventLifecycleState.cancelled
                ? '자동 환불이 완료된 금액 기준으로 집계했어요.'
                : pendingValue > 0
                ? '현재 ${_formatCurrency(summary.currentRevenue)} · 심사 승인 시 +${_formatCurrency(summary.pendingRevenue)}'
                : '현재 ${_formatCurrency(summary.currentRevenue)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (summary.groupSummaries.isNotEmpty) ...[
            const SizedBox(height: MinglitSpacing.medium),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              groupTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            ...summary.groupSummaries.map(
              (groupSummary) => Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.small),
                child: _GroupRevenueRow(
                  state: state,
                  groupSummary: groupSummary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CompletedStatsCard extends StatelessWidget {
  const _CompletedStatsCard({required this.summary});

  final _EventPageSummary summary;

  @override
  Widget build(BuildContext context) {
    final averageRevenue = summary.confirmedCount == 0
        ? 0
        : summary.currentRevenue ~/ summary.confirmedCount;

    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatsRow(
            label: '전체 객단가',
            value: _formatCurrency(averageRevenue),
            suffix: summary.confirmedCount == 0
                ? null
                : '(${_formatCurrency(summary.currentRevenue)} ÷ ${summary.confirmedCount}명)',
          ),
          if (summary.groupSummaries.isNotEmpty) ...[
            const SizedBox(height: MinglitSpacing.small),
            Divider(color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: MinglitSpacing.small),
            ...summary.groupSummaries.map(
              (groupSummary) => Padding(
                padding: const EdgeInsets.only(bottom: MinglitSpacing.xsmall),
                child: _StatsRow(
                  label: groupSummary.label,
                  value: _formatCurrency(
                    groupSummary.confirmedCount == 0
                        ? 0
                        : groupSummary.currentRevenue ~/
                              groupSummary.confirmedCount,
                  ),
                  suffix: '(${groupSummary.confirmedCount}명 참석)',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryGroupBreakdown extends StatelessWidget {
  const _EntryGroupBreakdown({
    required this.event,
    required this.state,
    required this.summary,
  });

  final Event event;
  final _EventLifecycleState state;
  final _EventPageSummary summary;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          for (var i = 0; i < summary.groupSummaries.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            _EntryGroupTile(
              event: event,
              state: state,
              summary: summary.groupSummaries[i],
            ),
          ],
        ],
      ),
    );
  }
}

class _EntryGroupTile extends StatelessWidget {
  const _EntryGroupTile({
    required this.event,
    required this.state,
    required this.summary,
  });

  final Event event;
  final _EventLifecycleState state;
  final _EntryGroupSummary summary;

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            summary.label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),
          Wrap(
            spacing: MinglitSpacing.medium,
            runSpacing: MinglitSpacing.xsmall,
            children: [
              _MetricText(
                label: state == _EventLifecycleState.completed ? '참석' : '확정',
                value: summary.confirmedCount,
              ),
              if (summary.pendingCount > 0 &&
                  state == _EventLifecycleState.scheduled)
                _MetricText(label: '대기', value: summary.pendingCount),
              if (summary.refundedCount > 0)
                _MetricText(label: '환불', value: summary.refundedCount),
            ],
          ),
        ],
      ),
    );

    if (state == _EventLifecycleState.scheduled ||
        state == _EventLifecycleState.emptyApplications) {
      return InkWell(
        onTap: () {
          unawaited(
            EventApplicationListRoute(
              partyId: event.partyId,
              eventId: event.id,
              groupId: summary.group.id,
            ).push<void>(context),
          );
        },
        child: content,
      );
    }

    return content;
  }
}

class _GroupRevenueRow extends StatelessWidget {
  const _GroupRevenueRow({
    required this.state,
    required this.groupSummary,
  });

  final _EventLifecycleState state;
  final _EntryGroupSummary groupSummary;

  @override
  Widget build(BuildContext context) {
    final value = state == _EventLifecycleState.completed
        ? _formatCurrency(
            groupSummary.confirmedCount == 0
                ? 0
                : groupSummary.currentRevenue ~/ groupSummary.confirmedCount,
          )
        : _formatCurrency(groupSummary.currentRevenue);
    final suffix = state == _EventLifecycleState.completed
        ? '(${groupSummary.confirmedCount}명)'
        : '/ 최대 ${_formatCurrency(groupSummary.maxRevenue)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                groupSummary.label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            Text(
              suffix,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        if (state != _EventLifecycleState.completed) ...[
          const SizedBox(height: MinglitSpacing.xsmall),
          MinglitCapacityBar(
            total: groupSummary.maxRevenue == 0 ? 1 : groupSummary.maxRevenue,
            filled: groupSummary.currentRevenue,
            pending: groupSummary.pendingRevenue,
          ),
        ],
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: child,
      ),
    );
  }
}

class _MetricText extends StatelessWidget {
  const _MetricText({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          TextSpan(
            text: '$value',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StackedMetric extends StatelessWidget {
  const _StackedMetric({
    required this.value,
    required this.label,
  });

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.label,
    required this.value,
    this.suffix,
  });

  final String label;
  final String value;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (suffix != null)
                  TextSpan(
                    text: ' $suffix',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _VisibilityChip extends StatelessWidget {
  const _VisibilityChip({required this.visibility});

  final String visibility;

  @override
  Widget build(BuildContext context) {
    final isPrivate = visibility == 'private';
    final icon = isPrivate ? Icons.lock_outline : Icons.public;
    final label = isPrivate ? '비공개' : '공개';
    final description = isPrivate
        ? '비공개 이벤트는 링크를 아는 사용자만 볼 수 있어요.'
        : '공개 이벤트는 탐색과 목록에서 노출돼요.';

    return InkWell(
      borderRadius: BorderRadius.circular(MinglitRadius.chip),
      onTap: () => context.showMinglitInfo(description),
      child: _ChipBox(
        foregroundColor: isPrivate
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Theme.of(context).colorScheme.primary,
        backgroundColor: isPrivate
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).colorScheme.primaryContainer,
        icon: icon,
        label: label,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status) {
      case 'cancelled':
        return _ChipBox(
          foregroundColor: colorScheme.error,
          backgroundColor: colorScheme.errorContainer,
          label: '취소',
        );
      case 'completed':
        return _ChipBox(
          foregroundColor: colorScheme.onSurfaceVariant,
          backgroundColor: colorScheme.surfaceContainerHighest,
          label: '완료',
        );
      default:
        return _ChipBox(
          foregroundColor: colorScheme.primary,
          backgroundColor: colorScheme.primaryContainer,
          label: '모집',
        );
    }
  }
}

class _EventDDayChip extends StatelessWidget {
  const _EventDDayChip({
    required this.event,
    required this.state,
  });

  final Event event;
  final _EventLifecycleState state;

  @override
  Widget build(BuildContext context) {
    final days = _calendarDayDifference(event.startTime, DateTime.now());

    if (state == _EventLifecycleState.completed) {
      final elapsed = days <= 0 ? days.abs() : 0;

      // Fix #2109: Completed state needs the neutral outline D+N visual from
      // the new spec. Force MinglitDDayChip into its outline tier while
      // keeping the completed semantics/label outside the widget.
      return Semantics(
        label: '이벤트 종료 후 $elapsed일 경과',
        child: ExcludeSemantics(
          child: MinglitDDayChip(
            daysUntil: 8,
            label: 'D+$elapsed',
          ),
        ),
      );
    }

    if (state == _EventLifecycleState.cancelled) {
      return Semantics(
        label: days <= 0 ? '취소된 이벤트 일정 도래' : '취소된 이벤트까지 $days일 남음',
        child: ExcludeSemantics(
          child: MinglitDDayChip(
            daysUntil: days <= 0 ? 8 : days,
            label: days <= 0 ? '오늘' : 'D-$days',
          ),
        ),
      );
    }

    return MinglitDDayChip(daysUntil: days <= 0 ? 0 : days);
  }
}

class _ChipBox extends StatelessWidget {
  const _ChipBox({
    required this.foregroundColor,
    required this.backgroundColor,
    required this.label,
    this.icon,
  });

  final Color foregroundColor;
  final Color backgroundColor;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _calendarDayDifference(DateTime target, DateTime now) {
  final start = DateTime(now.year, now.month, now.day);
  final end = DateTime(target.year, target.month, target.day);
  return end.difference(start).inDays;
}

String _formatCurrency(int value) {
  final formatter = NumberFormat.decimalPattern('ko');
  return '${formatter.format(value)}원';
}
