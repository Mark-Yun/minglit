import 'dart:async';

import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyCurationScreen extends ConsumerStatefulWidget {
  const PartyCurationScreen({required this.type, super.key});

  final EventFeedType type;

  @override
  ConsumerState<PartyCurationScreen> createState() =>
      _PartyCurationScreenState();
}

class _PartyCurationScreenState extends ConsumerState<PartyCurationScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when entering the screen
    unawaited(
      Future.microtask(() {
        ref.invalidate(fetchEventFeedProvider(type: widget.type));
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventFeedProvider(type: widget.type));

    return Scaffold(
      appBar: AppBar(title: Text(widget.type.title), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate the raw data provider to force a re-fetch
          return ref.refresh(
            fetchEventFeedProvider(type: widget.type).future,
          );
        },
        child: MinglitAsyncValueWidget(
          value: eventsAsync,
          data: (events) {
            if (events.isEmpty) {
              return Stack(
                children: [
                  ListView(), // For Pull-to-refresh to work on empty list
                  const Center(child: Text('현재 표시할 파티가 없습니다.')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              itemCount: events.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: MinglitSpacing.medium),
              itemBuilder: (context, index) {
                final event = events[index];
                return MinglitEventCard(
                  event: event,
                  width: double.infinity,
                  onTap: () {
                    unawaited(
                      EventDetailRoute(eventId: event.id).push<void>(context),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
