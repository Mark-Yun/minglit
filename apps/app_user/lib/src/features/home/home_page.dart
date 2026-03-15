import 'dart:async';

import 'package:app_user/src/features/auth/logic/auth_coordinator.dart';
import 'package:app_user/src/features/event/logic/event_coordinator.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/explore/widgets/filter_chip_bar.dart';
import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Home page — explore recommendation content merged into home.
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final homeCoordinator = ref.read(homeCoordinatorProvider);
    final eventCoordinator = ref.read(eventCoordinatorProvider);
    final recommendationAsync = ref.watch(recommendationEventsProvider);

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            titleSpacing: 0,
            title: Row(
              children: [
                const SizedBox(width: MinglitSpacing.medium),
                GestureDetector(
                  onTap: () {
                    unawaited(
                      _scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    );
                  },
                  child: MinglitTheme.appBarLogo(height: 36),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () => const SearchRoute().push<void>(context),
              ),
              if (user != null) ...[
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: homeCoordinator.pushNotificationCenter,
                ),
                GestureDetector(
                  onTap: () => const MyPageRoute().push<void>(context),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundImage: user.userMetadata?['avatar_url'] != null
                        ? NetworkImage(
                            user.userMetadata!['avatar_url'] as String,
                          )
                        : null,
                    onBackgroundImageError:
                        user.userMetadata?['avatar_url'] != null
                        ? (_, _) {}
                        : null,
                    child: user.userMetadata?['avatar_url'] == null
                        ? const Icon(Icons.person, size: 14)
                        : null,
                  ),
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  // Fix #102: use go (not push) so GoRouter redirect fires after login
                  onPressed: () =>
                      ref.read(authCoordinatorProvider).goToLogin(from: '/'),
                ),
              const SizedBox(width: MinglitSpacing.small),
            ],
            // Fix #76: use theme color instead of
            // hardcoded white for dark mode support
            backgroundColor: Theme.of(context).colorScheme.surface,
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
                padding: const EdgeInsets.only(
                  top: MinglitSpacing.small,
                  bottom: MinglitSpacing.medium,
                ),
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
    );
  }
}
