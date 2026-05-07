import 'dart:async';

import 'package:app_user/src/features/tickets/active_event_banners_provider.dart';
import 'package:app_user/src/features/tickets/widgets/event_ongoing_banner.dart';
import 'package:app_user/src/logic/ticket_event_meta.dart';
import 'package:app_user/src/routing/app_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class MyTicketsPage extends ConsumerWidget {
  const MyTicketsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(activeEventBannersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('내 티켓')),
      body: MinglitAsyncValueWidget<List<ActiveEventBannerItem>>(
        value: bannersAsync,
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(MinglitSpacing.xlarge),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.confirmation_number_outlined,
                      size: MinglitIconSize.display,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    Text(
                      '활성 이벤트가 없어요',
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                    Text(
                      '다가올 이벤트와 지난 회고는\n구매내역에서 볼 수 있어요',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MinglitSpacing.medium),
                    // spec: my_tickets_page.html#empty-state — vertical column, height 40 each
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            onPressed: () => ref
                                .read(appCoordinatorProvider)
                                .pushPurchaseHistory(),
                            child: const Text('구매내역 보기'),
                          ),
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                        SizedBox(
                          height: 40,
                          child: OutlinedButton(
                            onPressed: () =>
                                ref.read(appCoordinatorProvider).goToHome(),
                            child: const Text('이벤트 둘러보기'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.small),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final coordinator = ref.read(appCoordinatorProvider);
              final application = item.application;
              return EventOngoingBanner(
                application: application,
                phase: item.phase,
                onMarkResultsViewed: () {
                  unawaited(_markResultsViewed(ref, application.id));
                },
                onOpenDetail: () =>
                    coordinator.pushEventDetail(application.eventId),
                onOpenQr: () => coordinator.pushTicketQR(
                  application.ticketId,
                  eventMeta: _buildTicketEventMeta(application),
                ),
                onOpenMatching: () =>
                    coordinator.pushEventMatching(application.eventId),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _markResultsViewed(WidgetRef ref, String applicationId) async {
    // Fix #2123: Only invalidate provider when mutation succeeds.
    // A finally-block invalidation after failure re-shows resultsUnviewed banner
    // and triggers repeated calls on each subsequent tap.
    try {
      await ref
          .read(eventRepositoryProvider)
          .markMatchResultsViewed(applicationId: applicationId);
      ref.invalidate(activeEventBannersProvider);
    } catch (e, st) {
      debugPrint('markMatchResultsViewed failed: $e\n$st');
    }
  }

  TicketEventMeta? _buildTicketEventMeta(EventApplication application) {
    final event = application.event;
    final title = event?.title ?? event?.party?.title;
    if (event == null || title == null) return null;
    return TicketEventMeta(
      eventTitle: title,
      eventDateTime: event.startTime,
      eventVenue: event.location?.name ?? event.party?.location?.name,
      ticketName: application.ticket?.name,
    );
  }
}
