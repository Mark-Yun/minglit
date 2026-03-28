import 'dart:async';

import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Event application management page — grouped by event with inline approve/reject.
class EventApplicationManagePage extends ConsumerStatefulWidget {
  const EventApplicationManagePage({super.key});

  @override
  ConsumerState<EventApplicationManagePage> createState() =>
      _EventApplicationManagePageState();
}

class _EventApplicationManagePageState
    extends ConsumerState<EventApplicationManagePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final partnerAsync = ref.watch(currentPartnerInfoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('신청관리'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대기중'),
            Tab(text: '승인됨'),
            Tab(text: '거절됨'),
          ],
        ),
      ),
      body: partnerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
        data: (partner) {
          if (partner == null) {
            return const Center(child: Text('파트너 정보를 불러올 수 없습니다'));
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['pending', 'pending_review'],
                showActions: true,
              ),
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['approved', 'paid'],
                showActions: false,
              ),
              _ApplicationTab(
                partnerId: partner.id,
                statusFilter: const ['rejected'],
                showActions: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Provider to fetch applications grouped by event for a partner.
final FutureProviderFamily<
  Map<Event, List<EventApplication>>,
  ({String partnerId, List<String> statusFilter})
>
eventApplicationsGroupedProvider = FutureProvider.family
    .autoDispose<
      Map<Event, List<EventApplication>>,
      ({String partnerId, List<String> statusFilter})
    >(
      (ref, params) async {
        final eventRepo = ref.read(eventRepositoryProvider);

        // Get all upcoming events for this partner
        final events = await eventRepo.getUpcomingEvents(params.partnerId);

        final grouped = <Event, List<EventApplication>>{};

        for (final event in events) {
          final apps = await eventRepo.getApplicationsByEventId(event.id);
          final filtered = apps
              .where((a) => params.statusFilter.contains(a.status))
              .toList();
          if (filtered.isNotEmpty) {
            grouped[event] = filtered;
          }
        }

        return grouped;
      },
    );

class _ApplicationTab extends ConsumerWidget {
  const _ApplicationTab({
    required this.partnerId,
    required this.statusFilter,
    required this.showActions,
  });

  final String partnerId;
  final List<String> statusFilter;
  final bool showActions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupedAsync = ref.watch(
      eventApplicationsGroupedProvider(
        (partnerId: partnerId, statusFilter: statusFilter),
      ),
    );

    return groupedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('신청 목록을 불러올 수 없습니다'),
            const SizedBox(height: MinglitSpacing.small),
            FilledButton(
              onPressed: () => ref.invalidate(
                eventApplicationsGroupedProvider(
                  (partnerId: partnerId, statusFilter: statusFilter),
                ),
              ),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
      data: (grouped) {
        if (grouped.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: MinglitIconSize.xlarge * 2,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Text(
                  showActions ? '대기 중인 신청이 없습니다' : '해당 신청이 없습니다',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          );
        }

        final entries = grouped.entries.toList();
        final totalPending = grouped.values.fold<int>(
          0,
          (sum, apps) => sum + apps.length,
        );

        return Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(
                    eventApplicationsGroupedProvider(
                      (partnerId: partnerId, statusFilter: statusFilter),
                    ),
                  );
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final event = entries[index].key;
                    final apps = entries[index].value;
                    return _EventGroupSection(
                      event: event,
                      applications: apps,
                      showActions: showActions,
                      onApprove: (appId) => _approve(ref, context, appId),
                      onReject: (appId) =>
                          _showRejectDialog(ref, context, appId),
                    );
                  },
                ),
              ),
            ),
            // Bulk approve button (only for pending tab)
            if (showActions && totalPending > 0)
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.medium),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _bulkApprove(ref, context, grouped),
                      child: Text('전체 승인 ($totalPending건)'),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _approve(
    WidgetRef ref,
    BuildContext context,
    String appId,
  ) async {
    try {
      final client = ref.read(supabaseClientProvider);
      await client.functions.invoke(
        'partner-approve-application',
        body: {'action': 'approve', 'application_id': appId},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('승인되었습니다')),
        );
        ref.invalidate(eventApplicationsGroupedProvider);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('승인 실패: $e')),
        );
      }
    }
  }

  Future<void> _showRejectDialog(
    WidgetRef ref,
    BuildContext context,
    String appId,
  ) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신청 거절'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: '거절 사유를 입력하세요',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, reasonController.text),
            child: const Text('거절'),
          ),
        ],
      ),
    );
    reasonController.dispose();

    if (reason == null || reason.trim().isEmpty) return;

    try {
      final client = ref.read(supabaseClientProvider);
      await client.functions.invoke(
        'partner-reject-application',
        body: {'application_id': appId, 'reason': reason.trim()},
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거절되었습니다')),
        );
        ref.invalidate(eventApplicationsGroupedProvider);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('거절 실패: $e')),
        );
      }
    }
  }

  Future<void> _bulkApprove(
    WidgetRef ref,
    BuildContext context,
    Map<Event, List<EventApplication>> grouped,
  ) async {
    final total = grouped.values.fold<int>(0, (s, apps) => s + apps.length);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('전체 승인'),
        content: Text('대기 중인 $total건을 모두 승인하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('전체 승인'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final client = ref.read(supabaseClientProvider);
    final failures = <String>[];
    for (final event in grouped.keys) {
      try {
        await client.functions.invoke(
          'partner-approve-application',
          body: {'action': 'bulk_approve', 'event_id': event.id},
        );
      } on Exception catch (e) {
        failures.add('${event.title}: $e');
      }
    }
    if (context.mounted) {
      if (failures.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$total건 승인 완료')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '일부 승인 실패 (${failures.length}건): ${failures.first}',
            ),
          ),
        );
      }
      ref.invalidate(eventApplicationsGroupedProvider);
    }
  }
}

class _EventGroupSection extends StatelessWidget {
  const _EventGroupSection({
    required this.event,
    required this.applications,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  final Event event;
  final List<EventApplication> applications;
  final bool showActions;
  final void Function(String appId) onApprove;
  final void Function(String appId) onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFmt = DateFormat('M/d (E)', 'ko');
    final timeFmt = DateFormat('HH:mm');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Event header
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: MinglitSpacing.medium,
            vertical: MinglitSpacing.sm,
          ),
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.3,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${event.title ?? ''} · ${dateFmt.format(event.startTime)} ${timeFmt.format(event.startTime)}',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${applications.length}건 · ${event.currentParticipants}/${event.maxParticipants}명',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Application items
        ...applications.map(
          (app) => _ApplicationItem(
            application: app,
            showActions: showActions,
            onApprove: () => onApprove(app.id),
            onReject: () => onReject(app.id),
          ),
        ),
      ],
    );
  }
}

class _ApplicationItem extends StatelessWidget {
  const _ApplicationItem({
    required this.application,
    required this.showActions,
    required this.onApprove,
    required this.onReject,
  });

  final EventApplication application;
  final bool showActions;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = application.user;
    final name = user?.name ?? '이름 없음';
    final gender = user?.gender;
    final birthYear = user?.birthYear;
    final age = birthYear != null ? DateTime.now().year - birthYear : null;
    final timeAgo = _formatTimeAgo(application.createdAt);

    final genderText = switch (gender) {
      'male' => '남',
      'female' => '여',
      _ => null,
    };

    final subtitle = [
      if (age != null) '$age세',
      ?genderText,
      timeAgo,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.medium,
        vertical: MinglitSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
            child: Text(
              name.isNotEmpty ? name[0] : '?',
              style: theme.textTheme.titleSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: MinglitSpacing.sm),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(subtitle, style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          // Actions or status
          if (showActions) ...[
            IconButton(
              icon: const Icon(
                Icons.close,
                color: MinglitColors.error,
                size: MinglitIconSize.small,
              ),
              onPressed: onReject,
              tooltip: '거절',
              style: IconButton.styleFrom(
                shape: CircleBorder(
                  side: BorderSide(
                    color: theme.dividerColor,
                  ),
                ),
                minimumSize: const Size(36, 36),
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            IconButton(
              icon: Icon(
                Icons.check,
                color: theme.colorScheme.onPrimary,
                size: MinglitIconSize.small,
              ),
              onPressed: onApprove,
              tooltip: '승인',
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                minimumSize: const Size(36, 36),
              ),
            ),
          ] else
            _StatusBadge(status: application.status),
        ],
      ),
    );
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, color) = switch (status) {
      'approved' || 'paid' => ('승인', MinglitColors.success),
      'rejected' => ('거절', MinglitColors.error),
      _ => ('대기', theme.colorScheme.primary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
