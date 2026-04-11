import 'package:app_partner/src/features/checkin/qr_scanner_screen.dart';
import 'package:app_partner/src/logic/current_partner_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';
import 'package:riverpod/src/providers/future_provider.dart';

/// Check-in tab entry page.
///
/// Auto-selects event based on today's schedule:
/// - 0 events today → empty state with next event info
/// - 1 event today → direct to QR scanner
/// - 2+ events today → event selection bottom sheet → scanner
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
        // 1 event → direct to scanner
        if (events.length == 1) {
          return _ScannerWrapper(event: events.first);
        }

        // 0 or 2+ → show selection/empty page
        return _CheckinSelectionPage(events: events);
      },
    );
  }
}

/// Provider that fetches today's events for check-in.
/// "Today" = events starting within 3 hours before ~ 1 hour after end.
final FutureProviderFamily<List<Event>, String> todayEventsProvider =
    FutureProvider.family.autoDispose<List<Event>, String>((
      ref,
      partnerId,
    ) async {
      final repo = ref.read(eventRepositoryProvider);
      final upcoming = await repo.getUpcomingEvents(partnerId);
      final now = DateTime.now();

      return upcoming.where((e) {
        final earlyWindow = e.startTime.subtract(const Duration(hours: 3));
        final lateWindow = e.endTime.add(const Duration(hours: 1));
        return now.isAfter(earlyWindow) && now.isBefore(lateWindow);
      }).toList();
    });

/// Wraps QR scanner with event context (name, count) in dark theme.
class _ScannerWrapper extends StatelessWidget {
  const _ScannerWrapper({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          // Fix #652: 하드코딩 Color(0xFF6C3CE1) → MinglitPartnerColors.primary 토큰 사용
          seedColor: MinglitPartnerColors.primary,
          brightness: Brightness.dark,
        ),
      ),
      child: QRScannerScreen(event: event),
    );
  }
}

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
                  Icons.qr_code_scanner,
                  size: MinglitIconSize.xlarge * 2,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: MinglitSpacing.medium),
                Text('오늘 예정된 이벤트가 없습니다', style: theme.textTheme.titleMedium),
                const SizedBox(height: MinglitSpacing.small),
                Text(
                  '이벤트 당일에 체크인을 시작할 수 있어요',
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
              '이벤트를 선택하세요',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '오늘 ${events.length}개 이벤트가 진행됩니다',
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
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => _ScannerWrapper(event: event),
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
                                    event.title ?? '',
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
