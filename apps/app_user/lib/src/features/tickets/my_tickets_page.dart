import 'dart:async';

import 'package:app_user/src/features/tickets/active_event_banners_provider.dart';
import 'package:app_user/src/features/tickets/widgets/event_ongoing_banner.dart';
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
                      '참여 중인 이벤트가 없습니다',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: MinglitSpacing.large),
                    Wrap(
                      spacing: MinglitSpacing.small,
                      runSpacing: MinglitSpacing.small,
                      alignment: WrapAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => ref
                              .read(appCoordinatorProvider)
                              .pushPurchaseHistory(),
                          child: const Text('구매 내역 보기'),
                        ),
                        FilledButton(
                          onPressed: () =>
                              ref.read(appCoordinatorProvider).goToHome(),
                          child: const Text('홈으로 이동'),
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
              return EventOngoingBanner(
                application: item.application,
                phase: item.phase,
                onMarkResultsViewed: () {
                  unawaited(_markResultsViewed(ref, item.application.id));
                },
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
}
