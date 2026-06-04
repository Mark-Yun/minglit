import 'dart:async';

import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:app_partner/src/logic/event_operation_phase.dart';
import 'package:app_partner/src/ui/screens/ongoing_event_list_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod/misc.dart';

/// Check-in tab entry page.
///
/// Auto-selects event based on today's schedule:
/// - 0 events today → empty state with next event info
/// - 1 event in operation window → direct to OngoingEventListPage
/// - 2+ operation-window events → selection list → OngoingEventListPage
class CheckinPlaceholderPage extends ConsumerWidget {
  const CheckinPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnerAsync = ref.watch(currentPartnerInfoProvider);

    return partnerAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: MinglitTheme.simpleAppBar(title: '체크인'),
        body: Center(child: Text('오류가 발생했습니다: $e')),
      ),
      data: (partner) {
        if (partner == null) {
          return Scaffold(
            appBar: MinglitTheme.simpleAppBar(title: '체크인'),
            body: const Center(child: Text('파트너 정보를 불러올 수 없습니다')),
          );
        }
        return _CheckinEntryPage(partnerId: partner.id);
      },
    );
  }
}

class _CheckinEntryPage extends ConsumerWidget {
  const _CheckinEntryPage({required this.partnerId});
  final String partnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(todayEventsProvider(partnerId));

    return eventsAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: MinglitTheme.simpleAppBar(title: '체크인'),
        body: const Center(child: Text('이벤트를 불러올 수 없습니다')),
      ),
      data: (events) {
        // 1 event → direct to the canonical ongoing operation surface.
        if (events.length == 1) {
          return OngoingEventListPage(event: events.first);
        }

        // 0 or 2+ → show selection/empty page
        return _CheckinSelectionPage(events: events);
      },
    );
  }
}

/// Provider that fetches events for the ongoing operation surface.
/// Window = T-7 through end + 24h.
final FutureProviderFamily<List<Event>, String> todayEventsProvider =
    FutureProvider.family.autoDispose<List<Event>, String>((
      ref,
      partnerId,
    ) async {
      final repo = ref.read(eventRepositoryProvider);
      final upcoming = await repo.getPartnerOperationWindowEvents(partnerId);

      return upcoming.where(isOngoingListWindow).toList();
    });

/// Page shown when 0 or 2+ events today.
class _CheckinSelectionPage extends StatelessWidget {
  const _CheckinSelectionPage({required this.events});
  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (events.isEmpty) {
      return Scaffold(
        appBar: MinglitTheme.simpleAppBar(title: '체크인'),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: MinglitIconSize.hero,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Text('오늘 예정된 이벤트가 없습니다', style: theme.textTheme.titleMedium),
                const SizedBox(height: MinglitSpacing.small),
                Text(
                  '진행 7일 전부터 참가자 리스트를 확인할 수 있어요',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 2+ events → selection list
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '체크인'),
      body: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '운영할 이벤트를 선택하세요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '진행 임박/진행 중 이벤트 ${events.length}개',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Expanded(
              child: ListView.separated(
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: MinglitSpacing.small),
                itemBuilder: (context, index) {
                  final event = events[index];
                  final timeFmt = DateFormat('HH:mm');
                  final now = DateTime.now();
                  final isLive =
                      now.isAfter(event.startTime) &&
                      now.isBefore(event.endTime);

                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(MinglitRadius.card),
                      onTap: () {
                        unawaited(
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  OngoingEventListPage(event: event),
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(MinglitSpacing.medium),
                        child: Row(
                          children: [
                            // Time
                            Text(
                              timeFmt.format(event.startTime),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: isLive
                                    ? MinglitColors.success
                                    : theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: MinglitSpacing.sm),
                            // Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    // Fix #1742: title is nullable.
                                    event.party?.title ?? event.title ?? '',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  Text(
                                    '${event.currentParticipants}/${event.maxParticipants}명',
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            // Status
                            if (isLive)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: MinglitSpacing.small,
                                  vertical: MinglitSpacing.xsmall,
                                ),
                                decoration: BoxDecoration(
                                  color: MinglitColors.success.withValues(
                                    alpha: MinglitOpacity.highlight,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    MinglitRadius.small,
                                  ),
                                ),
                                child: Text(
                                  'LIVE',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: MinglitColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            else
                              Icon(
                                Icons.chevron_right,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
