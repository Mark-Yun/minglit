import 'package:app_user/src/features/partner/logic/partner_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Full-page list of events for a specific partner.
class PartnerEventsPage extends ConsumerWidget {
  const PartnerEventsPage({
    required this.partnerId,
    required this.partnerName,
    super.key,
  });

  final String partnerId;
  final String partnerName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(partnerEventsProvider(partnerId: partnerId));

    return Scaffold(
      appBar: AppBar(
        title: Text('$partnerName 이벤트'),
        centerTitle: true,
      ),
      body: MinglitAsyncValueWidget(
        value: eventsAsync,
        data: (events) {
          if (events.isEmpty) {
            return Center(
              child: Text(
                '등록된 이벤트가 없습니다.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            );
          }
          return ListView.builder(
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              // Fix #634: home_coordinator 직접 참조 → partner_coordinator 전환
              return MinglitEventCard(
                event: event,
                onTap: () =>
                    ref.read(partnerCoordinatorProvider).pushEventDetail(event.id),
              );
            },
          );
        },
      ),
    );
  }
}
