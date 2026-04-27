part of 'event_application_manage_page.dart';

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
      eventApplicationsGroupedProvider((
        partnerId: partnerId,
        statusFilter: statusFilter,
      )),
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
                eventApplicationsGroupedProvider((
                  partnerId: partnerId,
                  statusFilter: statusFilter,
                )),
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
                    eventApplicationsGroupedProvider((
                      partnerId: partnerId,
                      statusFilter: statusFilter,
                    )),
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

  // Fix #653: Supabase 직접 접근 → EventRepository 분리
  Future<void> _approve(
    WidgetRef ref,
    BuildContext context,
    String appId,
  ) async {
    try {
      final eventRepo = ref.read(eventRepositoryProvider);
      await eventRepo.approveApplication(applicationId: appId);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('승인되었습니다')));
        ref.invalidate(eventApplicationsGroupedProvider);
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('승인 실패: $e')));
      }
    }
  }

  Future<void> _showRejectDialog(
    WidgetRef ref,
    BuildContext context,
    String appId,
  ) async {
    // Fix #1316: Use _RejectDialog StatefulWidget so the TextEditingController
    // is disposed by Flutter after the dialog close animation completes,
    // not immediately when showDialog resolves.
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => const _RejectDialog(),
    );

    if (reason == null || reason.trim().isEmpty) return;

    // Fix #653: Supabase 직접 접근 → EventRepository 분리
    try {
      final eventRepo = ref.read(eventRepositoryProvider);
      await eventRepo.rejectApplication(
        applicationId: appId,
        reason: reason.trim(),
      );
      if (context.mounted) {
        // Fix #1316: Capture container before scheduling — WidgetRef is unsafe
        // after unmount, but ProviderContainer is lifecycle-independent.
        final container = ProviderScope.containerOf(context, listen: false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('거절되었습니다')));
        // Defer invalidate by one frame so dialog close animation completes
        // before the provider rebuild — avoids _FocusInheritedScope
        // build-scope conflict.
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => container.invalidate(eventApplicationsGroupedProvider),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('거절 실패: $e')));
      }
    }
  }

  Future<void> _bulkApprove(
    WidgetRef ref,
    BuildContext context,
    Map<Event, List<EventApplication>> grouped,
  ) async {
    final total = grouped.values.fold<int>(0, (s, apps) => s + apps.length);
    final confirmed = await MinglitAlert.showConfirm(
      context: context,
      title: '전체 승인',
      content: '대기 중인 $total건을 모두 승인하시겠습니까?',
      confirmText: '전체 승인',
    );

    if (!confirmed) return;

    // Fix #653: Supabase 직접 접근 → EventRepository 분리
    final eventRepo = ref.read(eventRepositoryProvider);
    final failures = <String>[];
    for (final event in grouped.keys) {
      try {
        await eventRepo.bulkApproveApplications(eventId: event.id);
      } on Exception catch (e) {
        failures.add('${event.title}: $e');
      }
    }
    if (context.mounted) {
      // Fix #1316: Capture container before scheduling — WidgetRef is unsafe
      // after unmount, but ProviderContainer is lifecycle-independent.
      final container = ProviderScope.containerOf(context, listen: false);
      if (failures.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$total건 승인 완료')));
      } else {
        // Fix #1953: show all failed event titles, not just the first.
        final failureList = failures.join('\n');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('일부 승인 실패 (${failures.length}건):\n$failureList'),
          ),
        );
      }
      // Defer invalidate by one frame so dialog close animation completes
      // before the provider rebuild — avoids _FocusInheritedScope
      // build-scope conflict.
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => container.invalidate(eventApplicationsGroupedProvider),
      );
    }
  }
}
