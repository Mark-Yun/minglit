import 'dart:async' show unawaited;

import 'package:app_partner/src/features/home/partner_dashboard_controller.dart';
import 'package:app_partner/src/logic/event_operation_phase.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:app_partner/src/ui/screens/ongoing_event_list_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

enum ActiveEventFilter {
  all(null, '전체'),
  recruiting('recruiting', '모집 중'),
  upcoming('upcoming', '진행 임박'),
  live('live', 'LIVE')
  ;

  const ActiveEventFilter(this.queryValue, this.label);

  final String? queryValue;
  final String label;

  static ActiveEventFilter fromQuery(String? value) {
    for (final filter in ActiveEventFilter.values) {
      if (filter.queryValue == value) return filter;
    }
    return ActiveEventFilter.all;
  }
}

class PartnerActiveEventListPage extends ConsumerStatefulWidget {
  const PartnerActiveEventListPage({this.initialFilter, super.key});

  final String? initialFilter;

  @override
  ConsumerState<PartnerActiveEventListPage> createState() =>
      _PartnerActiveEventListPageState();
}

class _PartnerActiveEventListPageState
    extends ConsumerState<PartnerActiveEventListPage> {
  late ActiveEventFilter _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = ActiveEventFilter.fromQuery(widget.initialFilter);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(partnerDashboardControllerProvider);
    final isInitialLoading =
        state.status.isLoading &&
        state.recruitingEvents.isEmpty &&
        state.preparingEvents.isEmpty &&
        state.liveEvents.isEmpty;

    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '활성 이벤트'),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(partnerDashboardControllerProvider.notifier)
            .loadDashboardData(),
        child: isInitialLoading
            ? const _LoadingState()
            : state.status.hasError &&
                  state.recruitingEvents.isEmpty &&
                  state.preparingEvents.isEmpty &&
                  state.liveEvents.isEmpty
            ? _ErrorState(
                onRetry: () => ref
                    .read(partnerDashboardControllerProvider.notifier)
                    .loadDashboardData(),
              )
            : _ActiveEventListContent(
                state: state,
                selectedFilter: _selectedFilter,
                onFilterChanged: (filter) {
                  setState(() => _selectedFilter = filter);
                },
                onOpenDetail: (event) => EventDetailRoute(
                  partyId: event.partyId,
                  eventId: event.id,
                ).push<void>(context),
                onOpenOperation: (event) {
                  unawaited(
                    Navigator.of(context).push<void>(
                      MaterialPageRoute(
                        builder: (_) => OngoingEventListPage(event: event),
                      ),
                    ),
                  );
                },
                onCreateEvent: () => _openCreateDestination(state),
              ),
      ),
    );
  }

  Future<void> _openCreateDestination(PartnerDashboardState state) async {
    if (state.activeParties.isEmpty) {
      unawaited(const PartyCreateRoute().push<void>(context));
      return;
    }
    if (state.activeParties.length == 1) {
      unawaited(
        EventCreateRoute(partyId: state.activeParties.first.id).push<void>(
          context,
        ),
      );
      return;
    }

    final selected = await showMinglitBottomSheet<Party>(
      context: context,
      title: '이벤트를 만들 파티를 선택하세요',
      child: _PartySelectionList(parties: state.activeParties),
    );
    if (selected == null || !mounted) return;
    unawaited(EventCreateRoute(partyId: selected.id).push<void>(context));
  }
}

class _ActiveEventListContent extends StatelessWidget {
  const _ActiveEventListContent({
    required this.state,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onOpenDetail,
    required this.onOpenOperation,
    required this.onCreateEvent,
  });

  final PartnerDashboardState state;
  final ActiveEventFilter selectedFilter;
  final ValueChanged<ActiveEventFilter> onFilterChanged;
  final ValueChanged<Event> onOpenDetail;
  final ValueChanged<Event> onOpenOperation;
  final VoidCallback onCreateEvent;

  @override
  Widget build(BuildContext context) {
    final recruiting = _sorted(state.recruitingEvents);
    final upcoming = _sorted(state.preparingEvents);
    final live = _sorted(state.liveEvents);
    final allEvents = _sorted([...live, ...upcoming, ...recruiting]);
    final filteredEvents = switch (selectedFilter) {
      ActiveEventFilter.all => allEvents,
      ActiveEventFilter.recruiting => recruiting,
      ActiveEventFilter.upcoming => upcoming,
      ActiveEventFilter.live => live,
    };
    final totalCount = allEvents.length;

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _SummaryHeader(
            totalCount: totalCount,
            recruitingCount: recruiting.length,
            upcomingCount: upcoming.length,
            liveCount: live.length,
          ),
        ),
        SliverToBoxAdapter(
          child: _StatsRow(
            recruitingCount: recruiting.length,
            upcomingCount: upcoming.length,
            liveCount: live.length,
            onFilterChanged: onFilterChanged,
          ),
        ),
        SliverPersistentHeader(
          pinned: true,
          delegate: _FilterHeaderDelegate(
            selectedFilter: selectedFilter,
            counts: {
              ActiveEventFilter.all: totalCount,
              ActiveEventFilter.recruiting: recruiting.length,
              ActiveEventFilter.upcoming: upcoming.length,
              ActiveEventFilter.live: live.length,
            },
            onFilterChanged: onFilterChanged,
          ),
        ),
        if (filteredEvents.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: MinglitEmptyState(
              icon: totalCount == 0
                  ? Icons.event_available_outlined
                  : Icons.filter_alt_off_outlined,
              title: totalCount == 0
                  ? '활성 이벤트가 없어요'
                  : '${selectedFilter.label} 이벤트가 없어요',
              subtitle: totalCount == 0
                  ? '새 이벤트를 만들면 모집 중 상태부터 이곳에 표시됩니다.'
                  : '다른 상태를 선택해 보세요.',
              actionLabel: totalCount == 0 ? '이벤트 만들기' : '전체 보기',
              onAction: totalCount == 0
                  ? onCreateEvent
                  : () => onFilterChanged(ActiveEventFilter.all),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              MinglitSpacing.medium,
              0,
              MinglitSpacing.medium,
              MinglitSpacing.large,
            ),
            sliver: SliverList.separated(
              itemBuilder: (context, index) {
                final event = filteredEvents[index];
                return _ActiveEventCard(
                  event: event,
                  onOpenDetail: () => onOpenDetail(event),
                  onOpenOperation: () => onOpenOperation(event),
                );
              },
              separatorBuilder: (_, _) =>
                  const SizedBox(height: MinglitSpacing.small),
              itemCount: filteredEvents.length,
            ),
          ),
      ],
    );
  }

  List<Event> _sorted(List<Event> events) {
    return [...events]..sort((a, b) {
      final phaseCompare = _phaseRank(getEventPhase(a)).compareTo(
        _phaseRank(getEventPhase(b)),
      );
      if (phaseCompare != 0 && selectedFilter == ActiveEventFilter.all) {
        return phaseCompare;
      }
      final timeCompare = a.startTime.compareTo(b.startTime);
      if (timeCompare != 0) return timeCompare;
      return b.currentParticipants.compareTo(a.currentParticipants);
    });
  }

  int _phaseRank(EventPhase phase) => switch (phase) {
    EventPhase.live => 0,
    EventPhase.checkinReady => 1,
    EventPhase.preStart => 2,
    EventPhase.recruiting => 3,
    EventPhase.ended => 4,
  };
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalCount,
    required this.recruitingCount,
    required this.upcomingCount,
    required this.liveCount,
  });

  final int totalCount;
  final int recruitingCount;
  final int upcomingCount;
  final int liveCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
        MinglitSpacing.small,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '운영 중인 이벤트 $totalCount개',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: MinglitSpacing.xsmall),
          Text(
            '모집 중 $recruitingCount · 진행 임박 $upcomingCount · LIVE $liveCount',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.recruitingCount,
    required this.upcomingCount,
    required this.liveCount,
    required this.onFilterChanged,
  });

  final int recruitingCount;
  final int upcomingCount;
  final int liveCount;
  final ValueChanged<ActiveEventFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MinglitSpacing.medium,
        MinglitSpacing.small,
        MinglitSpacing.medium,
        MinglitSpacing.medium,
      ),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: '모집 중',
              count: recruitingCount,
              onTap: () => onFilterChanged(ActiveEventFilter.recruiting),
            ),
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Expanded(
            child: _StatCard(
              label: '진행 임박',
              count: upcomingCount,
              onTap: () => onFilterChanged(ActiveEventFilter.upcoming),
            ),
          ),
          const SizedBox(width: MinglitSpacing.xsmall),
          Expanded(
            child: _StatCard(
              label: 'LIVE',
              count: liveCount,
              highlighted: liveCount > 0,
              onTap: () => onFilterChanged(ActiveEventFilter.live),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.count,
    required this.onTap,
    this.highlighted = false,
  });

  final String label;
  final int count;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = highlighted
        ? MinglitPartnerColors.primary
        : theme.colorScheme.onSurface;

    return Material(
      color: highlighted
          ? MinglitPartnerColors.primary.withValues(alpha: 0.08)
          : theme.colorScheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        side: BorderSide(
          color: highlighted
              ? MinglitPartnerColors.primary.withValues(alpha: 0.35)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: MinglitSpacing.xxsmall),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FilterHeaderDelegate({
    required this.selectedFilter,
    required this.counts,
    required this.onFilterChanged,
  });

  final ActiveEventFilter selectedFilter;
  final Map<ActiveEventFilter, int> counts;
  final ValueChanged<ActiveEventFilter> onFilterChanged;

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: overlapsContent
            ? [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: MinglitChipGroup(
        height: 48,
        children: [
          for (final filter in ActiveEventFilter.values)
            ChoiceChip(
              label: Text('${filter.label} ${counts[filter] ?? 0}'),
              selected: selectedFilter == filter,
              onSelected: (_) => onFilterChanged(filter),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeaderDelegate oldDelegate) {
    return selectedFilter != oldDelegate.selectedFilter ||
        counts != oldDelegate.counts;
  }
}

class _ActiveEventCard extends StatelessWidget {
  const _ActiveEventCard({
    required this.event,
    required this.onOpenDetail,
    required this.onOpenOperation,
  });

  final Event event;
  final VoidCallback onOpenDetail;
  final VoidCallback onOpenOperation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phase = getEventPhase(event);
    final isLive = phase == EventPhase.live;
    final isUpcoming =
        phase == EventPhase.preStart || phase == EventPhase.checkinReady;
    final percent = event.maxParticipants > 0
        ? (event.currentParticipants / event.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpenDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _EventHero(event: event, phase: phase),
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title ?? event.party?.title ?? '이벤트',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.xxsmall),
                  Text(
                    _eventMeta(event),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.small),
                  _CapacityBar(event: event, percent: percent),
                  const SizedBox(height: MinglitSpacing.medium),
                  if (isLive)
                    MinglitButton(
                      label: '참가자 체크인',
                      icon: Icons.qr_code_scanner,
                      size: MinglitButtonSize.medium,
                      onPressed: onOpenOperation,
                    )
                  else if (isUpcoming)
                    MinglitButton.secondary(
                      label: '참가자 리스트',
                      icon: Icons.list_alt_outlined,
                      size: MinglitButtonSize.medium,
                      onPressed: onOpenOperation,
                    )
                  else
                    Align(
                      alignment: Alignment.centerLeft,
                      child: MinglitButton.text(
                        label: '상세 보기',
                        icon: Icons.chevron_right,
                        onPressed: onOpenDetail,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventHero extends StatelessWidget {
  const _EventHero({required this.event, required this.phase});

  final Event event;
  final EventPhase phase;

  @override
  Widget build(BuildContext context) {
    final isLive = phase == EventPhase.live;
    final isUpcoming =
        phase == EventPhase.preStart || phase == EventPhase.checkinReady;
    return Container(
      height: 108,
      padding: const EdgeInsets.all(MinglitSpacing.small),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isLive
              ? [
                  MinglitColors.error.withValues(alpha: 0.18),
                  MinglitPartnerColors.primary.withValues(alpha: 0.14),
                ]
              : isUpcoming
              ? [
                  MinglitColors.warning.withValues(alpha: 0.18),
                  MinglitPartnerColors.primary.withValues(alpha: 0.12),
                ]
              : [
                  MinglitPartnerColors.primary.withValues(alpha: 0.16),
                  MinglitColors.success.withValues(alpha: 0.12),
                ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Wrap(
          spacing: MinglitSpacing.xsmall,
          runSpacing: MinglitSpacing.xsmall,
          children: [
            _HeroBadge(label: _phaseLabel(phase), isLive: isLive),
            _HeroBadge(
              label: '확정 ${event.currentParticipants}/${event.maxParticipants}',
            ),
            if (isUpcoming && phase == EventPhase.checkinReady)
              const _HeroBadge(label: '체크인 준비'),
          ],
        ),
      ),
    );
  }

  String _phaseLabel(EventPhase phase) => switch (phase) {
    EventPhase.live => 'LIVE',
    EventPhase.checkinReady => '체크인 가능',
    EventPhase.preStart => 'D-${_daysUntil(event.startTime)}',
    EventPhase.recruiting => '모집 중',
    EventPhase.ended => '종료',
  };

  int _daysUntil(DateTime time) {
    final days = time.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label, this.isLive = false});

  final String label;
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isLive
            ? MinglitColors.error.withValues(alpha: 0.9)
            : Colors.black.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(MinglitRadius.chip),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xxsmall,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({required this.event, required this.percent});

  final Event event;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentText = '${(percent * 100).round()}%';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '참가 확정 ${event.currentParticipants}명',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              percentText,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.xxsmall),
        LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          borderRadius: BorderRadius.circular(MinglitRadius.chip),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(child: MinglitCircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MinglitEmptyState(
            icon: Icons.error_outline,
            title: '목록을 불러오지 못했어요',
            subtitle: '잠시 후 다시 시도해 주세요.',
            actionLabel: '다시 시도',
            onAction: onRetry,
          ),
        ),
      ],
    );
  }
}

class _PartySelectionList extends StatelessWidget {
  const _PartySelectionList({required this.parties});

  final List<Party> parties;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      itemCount: parties.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final party = parties[index];
        return ListTile(
          title: Text(party.title),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).pop(party),
        );
      },
    );
  }
}

String _eventMeta(Event event) {
  final fmt = DateFormat('M월 d일 HH:mm');
  final locationName =
      event.location?.name ?? event.party?.location?.name ?? '장소 미정';
  return '${fmt.format(event.startTime)} · $locationName';
}
