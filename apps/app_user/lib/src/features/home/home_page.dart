import 'dart:async';

import 'package:app_user/src/features/home/widgets/category_chip_bar.dart';
import 'package:app_user/src/features/home/widgets/event_feed_section.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Main home dashboard with category chips and event feed sections.
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalidate all feed providers to force re-fetch
          for (final type in [
            EventFeedType.newArrivals,
            EventFeedType.closingSoon,
            EventFeedType.earlyBird,
          ]) {
            ref.invalidate(fetchEventFeedProvider(type: type));
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              snap: true,
              titleSpacing: 0,
              title: Row(
                children: [
                  const SizedBox(width: MinglitSpacing.medium),
                  MinglitTheme.appBarLogo(height: 36),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    unawaited(
                      const NotificationCenterRoute().push<void>(context),
                    );
                  },
                ),
                const SizedBox(width: MinglitSpacing.small),
              ],
              backgroundColor: MinglitColors.background,
              surfaceTintColor: Colors.transparent,
            ),
            const SliverToBoxAdapter(
              child: Column(
                children: [
                  CategoryChipBar(),
                  EventFeedSection(type: EventFeedType.newArrivals),
                  EventFeedSection(type: EventFeedType.closingSoon),
                  EventFeedSection(type: EventFeedType.earlyBird),
                  SizedBox(height: MinglitSpacing.xlarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
