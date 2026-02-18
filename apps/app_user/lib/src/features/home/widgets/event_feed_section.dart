import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// A horizontal scrolling event feed section with header and "더보기" button.
class EventFeedSection extends ConsumerWidget {
  const EventFeedSection({required this.type, super.key});

  final EventFeedType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventFeedProvider(type: type));
    final theme = Theme.of(context);
    final eventCoordinator = ref.read(eventCoordinatorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Padding(
          padding: const EdgeInsets.fromLTRB(
            MinglitSpacing.medium,
            MinglitSpacing.large,
            MinglitSpacing.small,
            MinglitSpacing.small,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(type.title, style: theme.textTheme.titleLarge),
              TextButton(
                onPressed: () {
                  eventCoordinator.pushEventCuration(type);
                },
                child: const Text('더보기'),
              ),
            ],
          ),
        ),
        // Horizontal List
        SizedBox(
          height: 280,
          child: MinglitAsyncValueWidget(
            value: eventsAsync,
            data: (events) {
              if (events.isEmpty) {
                return Center(
                  child: Text(
                    '현재 ${type.title}이 없습니다.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: MinglitColors.textSecondary,
                    ),
                  ),
                );
              }
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: MinglitSpacing.medium,
                ),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: MinglitSpacing.medium),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return MinglitEventCard(
                    event: event,
                    onTap: () {
                      eventCoordinator.pushEventDetail(event.id);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
