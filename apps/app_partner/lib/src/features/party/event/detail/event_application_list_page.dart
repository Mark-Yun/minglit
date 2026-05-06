import 'package:app_partner/src/logic/event_application_logic.dart';
import 'package:app_partner/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class EventApplicationListPage extends ConsumerWidget {
  const EventApplicationListPage({
    required this.eventId,
    this.groupId,
    super.key,
  });

  final String eventId;
  final String? groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bundleAsync = ref.watch(eventApplicationBundleProvider(eventId));

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('참가 신청'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: '대기중'),
              Tab(text: '승인됨'),
              Tab(text: '거절됨'),
              Tab(text: '환불'),
            ],
          ),
        ),
        body: MinglitAsyncValueWidget(
          value: bundleAsync,
          data: (bundle) => _DashboardBody(
            eventId: eventId,
            groupId: groupId,
            bundle: bundle,
          ),
        ),
      ),
    );
  }
}

// Fix #2126: 4-tab dashboard for partner event applications
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.eventId,
    required this.groupId,
    required this.bundle,
  });

  final String eventId;
  final String? groupId;
  final EventApplicationBundle bundle;

  @override
  Widget build(BuildContext context) {
    final applications = bundle.applications
        .where((app) => app.status != 'payment_failed')
        .toList();
    final pendingApps = applications
        .where((app) => {'pending', 'pending_review'}.contains(app.status))
        .toList();
    final approvedApps = applications
        .where((app) => app.status == 'approved')
        .toList();
    final rejectedApps = applications
        .where((app) => app.status == 'rejected')
        .toList();
    final refundApps = applications
        .where((app) => app.refundStatus != 'none')
        .toList();

    return TabBarView(
      children: [
        _PendingTab(
          eventId: eventId,
          selectedGroupId: groupId,
          bundle: bundle,
          pendingApplications: pendingApps,
        ),
        _ApplicationListTab(
          icon: Icons.check_circle_outline,
          title: '승인된 신청이 없습니다',
          subtitle: '승인 완료된 신청이 생기면 여기서 확인할 수 있습니다.',
          applications: approvedApps,
        ),
        _ApplicationListTab(
          icon: Icons.cancel_outlined,
          title: '거절된 신청이 없습니다',
          subtitle: '거절 처리된 신청 내역이 여기에 표시됩니다.',
          applications: rejectedApps,
        ),
        _ApplicationListTab(
          icon: Icons.undo_outlined,
          title: '환불 내역이 없습니다',
          subtitle: '환불 상태가 있는 신청이 생기면 여기서 확인할 수 있습니다.',
          applications: refundApps,
        ),
      ],
    );
  }
}

class _PendingTab extends StatelessWidget {
  const _PendingTab({
    required this.eventId,
    required this.selectedGroupId,
    required this.bundle,
    required this.pendingApplications,
  });

  final String eventId;
  final String? selectedGroupId;
  final EventApplicationBundle bundle;
  final List<EventApplication> pendingApplications;

  @override
  Widget build(BuildContext context) {
    final event = bundle.event;
    final groups = event.entryGroups ?? const <EntryGroup>[];
    final pendingCount = pendingApplications.length;
    final confirmedCount = bundle.applications
        .where((app) => app.status == 'approved')
        .length;

    final visibleGroups = selectedGroupId == null
        ? groups
        : groups.where((group) => group.id == selectedGroupId).toList();

    return ListView(
      padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
      children: [
        _EventHeroCard(event: event, eventId: eventId),
        const SizedBox(height: MinglitSpacing.medium),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '신청 현황',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: MinglitSpacing.small),
                _CapacityBar(
                  confirmed: confirmedCount,
                  pending: pendingCount,
                  total: event.maxParticipants,
                ),
                const SizedBox(height: MinglitSpacing.small),
                Text(
                  '확정 $confirmedCount명 · 대기 $pendingCount명 · 정원 ${event.maxParticipants}명',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: MinglitSpacing.medium),
        if (visibleGroups.isEmpty)
          const _EmptyState(
            icon: Icons.group_off_outlined,
            title: '입장 그룹이 없습니다',
            subtitle: '이 이벤트에 설정된 입장 그룹이 없습니다.',
          )
        else
          ...visibleGroups.map(
            (group) => Padding(
              padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
              child: _EntryGroupCard(
                event: event,
                eventId: eventId,
                group: group,
                counts: _GroupCounts.fromRows(
                  group.id,
                  bundle.groupCounts,
                  pendingApplications,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ApplicationListTab extends StatelessWidget {
  const _ApplicationListTab({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.applications,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<EventApplication> applications;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return _EmptyState(icon: icon, title: title, subtitle: subtitle);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(MinglitSpacing.screenEdge),
      itemBuilder: (context, index) =>
          _ApplicationCard(app: applications[index]),
      separatorBuilder: (_, _) => const SizedBox(height: MinglitSpacing.small),
      itemCount: applications.length,
    );
  }
}

class _EventHeroCard extends StatelessWidget {
  const _EventHeroCard({required this.event, required this.eventId});

  final Event event;
  final String eventId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => EventDetailRoute(
          partyId: event.partyId,
          eventId: eventId,
        ).go(context),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title ?? '제목 없는 이벤트',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: MinglitSpacing.small),
              Row(
                children: [
                  const Icon(Icons.schedule_outlined, size: 18),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Text(
                      DateFormat(
                        'M월 d일 (E) HH:mm',
                        'ko_KR',
                      ).format(event.startTime),
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: MinglitSpacing.small),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: MinglitSpacing.small),
                  Expanded(
                    child: Text(
                      event.location?.name ?? '장소 정보 없음',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntryGroupCard extends StatelessWidget {
  const _EntryGroupCard({
    required this.event,
    required this.eventId,
    required this.group,
    required this.counts,
  });

  final Event event;
  final String eventId;
  final EntryGroup group;
  final _GroupCounts counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final groupPendingLabel = counts.pending > 0
        ? '그룹 심사 시작 (${counts.pending}건)'
        : '검토할 신청 없음';
    final birthYearText = _birthYearText(group);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              group.label ?? _genderLabel(group.gender),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (group.label != null && group.label!.isNotEmpty) ...[
              const SizedBox(height: MinglitSpacing.xsmall),
              Text(
                _genderLabel(group.gender),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (birthYearText != null) ...[
              const SizedBox(height: MinglitSpacing.xsmall),
              Text(
                birthYearText,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (group.requiredVerificationIds.isNotEmpty) ...[
              const SizedBox(height: MinglitSpacing.small),
              Wrap(
                spacing: MinglitSpacing.small,
                runSpacing: MinglitSpacing.small,
                children: group.requiredVerificationIds
                    .map(
                      (id) => Chip(
                        label: Text('필수: $id'),
                        backgroundColor: MinglitPartnerColors.primary
                            .withValues(alpha: MinglitOpacity.highlight),
                        side: const BorderSide(
                          color: MinglitPartnerColors.primary,
                        ),
                        labelStyle: theme.textTheme.labelMedium?.copyWith(
                          color: MinglitPartnerColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            MinglitRadius.chip,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              children: [
                Expanded(
                  child: _CapacityBar(
                    confirmed: counts.confirmed,
                    pending: counts.pending,
                    total: counts.targetCapacity,
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.small,
                    vertical: MinglitSpacing.xsmall,
                  ),
                  decoration: BoxDecoration(
                    color: MinglitPartnerColors.primary.withValues(
                      alpha: MinglitOpacity.highlight,
                    ),
                    borderRadius: BorderRadius.circular(MinglitRadius.small),
                  ),
                  child: Text(
                    '${counts.confirmed + counts.pending}/${counts.targetCapacity}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: MinglitPartnerColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              '확정 ${counts.confirmed}명 · 대기 ${counts.pending}건 · 정원 ${counts.targetCapacity}명',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => EventApplicationReviewCarouselRoute(
                  partyId: event.partyId,
                  eventId: eventId,
                ).go(context),
                child: Text('전체 심사 시작 (${counts.pending}건)'),
              ),
            ),
            const SizedBox(height: MinglitSpacing.small),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: counts.pending > 0
                    ? () => EventApplicationReviewCarouselRoute(
                        partyId: event.partyId,
                        eventId: eventId,
                        groupId: group.id,
                      ).go(context)
                    : null,
                child: Text(groupPendingLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.app});

  final EventApplication app;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = app.user;
    final firstChar = (user?.name.isNotEmpty ?? false)
        ? user!.name.characters.first
        : null;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.small,
        ),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: MinglitPartnerColors.primary.withValues(
            alpha: MinglitOpacity.highlight,
          ),
          child: firstChar == null
              ? const Icon(Icons.person_outline)
              : Text(
                  firstChar,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: MinglitPartnerColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        title: Text(user?.name ?? '이름 없음'),
        subtitle: Text(
          _userSummary(user),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _StatusBadge(status: app.status),
            const SizedBox(width: MinglitSpacing.small),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () => EventApplicationDetailRoute(applicationId: app.id).go(
          context,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'pending_review' => ('심사 중', MinglitColors.warning),
      'approved' => ('승인됨', MinglitColors.success),
      'rejected' => ('거절됨', MinglitColors.error),
      'paid' => ('결제완료', MinglitPartnerColors.primary),
      _ => (status, Theme.of(context).colorScheme.outline),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: MinglitOpacity.highlight),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
        border: Border.all(color: color.withValues(alpha: MinglitOpacity.muted)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant.withValues(
                alpha: MinglitOpacity.muted,
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: MinglitSpacing.small),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityBar extends StatelessWidget {
  const _CapacityBar({
    required this.confirmed,
    required this.pending,
    required this.total,
  });
  final int confirmed;
  final int pending;
  final int total;
  @override
  Widget build(BuildContext context) {
    final safe = total > 0 ? total : 1;
    final filledFlex = (confirmed / safe * 100).round().clamp(0, 100);
    final pendingFlex = ((pending / safe) * 100).round().clamp(
      0,
      100 - filledFlex,
    );
    final emptyFlex = (100 - filledFlex - pendingFlex).clamp(0, 100);
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 12,
        child: Row(
          children: [
            if (filledFlex > 0)
              Expanded(
                flex: filledFlex,
                child: const ColoredBox(color: MinglitPartnerColors.primary),
              ),
            if (pendingFlex > 0)
              Expanded(
                flex: pendingFlex,
                child: ColoredBox(
                  color: MinglitPartnerColors.primary.withValues(
                    alpha: MinglitOpacity.muted,
                  ),
                ),
              ),
            if (emptyFlex > 0)
              Expanded(
                flex: emptyFlex,
                child: ColoredBox(color: MinglitColors.divider),
              ),
          ],
        ),
      ),
    );
  }
}

class _GroupCounts {
  const _GroupCounts({
    required this.confirmed,
    required this.pending,
    required this.targetCapacity,
  });

  final int confirmed;
  final int pending;
  final int targetCapacity;

  factory _GroupCounts.fromRows(
    String groupId,
    List<Map<String, dynamic>> rows,
    List<EventApplication> pendingApplications,
  ) {
    final row = rows.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['entry_group_id']?.toString() == groupId,
      orElse: () => null,
    );
    final confirmed = (row?['participant_count'] as num?)?.toInt() ?? 0;
    final targetCapacity = (row?['target_capacity'] as num?)?.toInt() ?? 0;
    final pending = pendingApplications
        .where((app) => app.ticket?.targetEntryGroupIds.contains(groupId) ?? false)
        .length;
    return _GroupCounts(
      confirmed: confirmed,
      pending: pending,
      targetCapacity: targetCapacity,
    );
  }
}

String _genderLabel(String? gender) => switch (gender) {
  'male' => '남성만',
  'female' => '여성만',
  _ => '제한 없음',
};

String? _birthYearText(EntryGroup group) {
  final min = group.birthYearMin;
  final max = group.birthYearMax;
  if (min != null && max != null) return '$min~$max년생';
  if (min != null) return '$min년생 이후';
  if (max != null) return '$max년생 이전';
  return null;
}

String _userSummary(UserProfile? user) {
  final gender = switch (user?.gender) {
    'male' => '남',
    'female' => '여',
    _ => null,
  };
  final birthYear = user?.birthYear?.toString();
  final parts = [if (gender != null) gender, if (birthYear != null) birthYear];
  return parts.isEmpty ? '정보 없음' : parts.join(' · ');
}
