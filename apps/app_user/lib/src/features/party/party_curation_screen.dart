import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCurationScreen extends ConsumerWidget {
  const PartyCurationScreen({
    required this.type,
    super.key,
  });

  final EventFeedType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventFeedProvider(type: type));

    return Scaffold(
      appBar: AppBar(
        title: Text(type.title),
        centerTitle: true,
      ),
      body: eventsAsync.when(
        data: (List<Event> events) {
          if (events.isEmpty) {
            return const Center(
              child: Text('현재 표시할 파티가 없습니다.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            itemCount: events.length,
            separatorBuilder: (context, index) =>
                const SizedBox(height: MinglitSpacing.medium),
            itemBuilder: (context, index) {
              return MinglitEventCard(
                event: events[index],
                width: double.infinity,
                onTap: () {
                  // TODO(Mark): Go to event detail
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (Object error, StackTrace? stack) => Center(
          child: Text('오류가 발생했습니다: $error'),
        ),
      ),
    );
  }
}
