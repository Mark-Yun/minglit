import 'package:app_user/src/features/explore/logic/explore_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Explore tab landing page showing event feed categories.
class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: MinglitTheme.simpleAppBar(title: '탐색', showBackButton: false),
      body: ListView(
        padding: const EdgeInsets.all(MinglitSpacing.medium),
        children: EventFeedType.values.map((type) {
          return Padding(
            padding: const EdgeInsets.only(bottom: MinglitSpacing.medium),
            child: Card(
              child: ListTile(
                leading: Icon(_iconFor(type), color: MinglitColors.primary),
                title: Text(type.title),
                subtitle: Text(type.sortLabel),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ref.read(exploreCoordinatorProvider).pushEventCuration(type);
                },
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _iconFor(EventFeedType type) {
    return switch (type) {
      EventFeedType.nearest => Icons.near_me,
      EventFeedType.newArrivals => Icons.fiber_new,
      EventFeedType.closingSoon => Icons.timer,
      EventFeedType.earlyBird => Icons.local_offer,
    };
  }
}
