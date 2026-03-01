import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/explore/widgets/filter_chip_bar.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:app_user/src/ui/shell/nav_visibility_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Home page — explore recommendation content merged into home.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final homeCoordinator = ref.read(homeCoordinatorProvider);
    final eventCoordinator = ref.read(eventCoordinatorProvider);
    final recommendationAsync = ref.watch(recommendationEventsProvider);

    return Scaffold(
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            ref.read(navVisibilityProvider.notifier).show();
          } else if (notification.direction == ScrollDirection.reverse) {
            ref.read(navVisibilityProvider.notifier).hide();
          }
          return false;
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
                  icon: const Icon(Icons.search),
                  onPressed: () => const SearchRoute().push<void>(context),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: homeCoordinator.pushNotificationCenter,
                ),
                const SizedBox(width: MinglitSpacing.small),
              ],
              backgroundColor: MinglitColors.background,
              surfaceTintColor: MinglitColors.transparent,
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: MinglitSpacing.small),
                child: ExploreFilterChipBar(),
              ),
            ),
            // ignore: use_minglit_async_value_widget, returns Sliver which is incompatible with Widget-based MinglitAsyncValueWidget
            recommendationAsync.when(
              data: (events) {
                if (events.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('추천 이벤트가 없습니다')),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.all(MinglitSpacing.medium),
                  sliver: SliverList.separated(
                    itemCount: events.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MinglitSpacing.small),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return MinglitEventCard(
                        event: event,
                        onTap: () => eventCoordinator.pushEventDetail(event.id),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: MinglitCircularProgressIndicator()),
              ),
              error: (_, _) => const SliverFillRemaining(
                child: SizedBox.shrink(),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.only(bottom: MinglitSpacing.xlarge),
            ),
          ],
        ),
      ),
    );
  }
}
