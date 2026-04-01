import 'dart:async';

import 'package:app_user/src/features/home/logic/home_coordinator.dart';
import 'package:app_user/src/features/home/widgets/event_now_bar.dart';
import 'package:app_user/src/logic/feed_state_provider.dart';
import 'package:app_user/src/routing/app_routes.dart';
import 'package:app_user/src/widgets/explore_filter_chip_bar.dart';
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
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      unawaited(ref.read(recommendationFeedProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final homeCoordinator = ref.read(homeCoordinatorProvider);
    final recommendationState = ref.watch(recommendationFeedProvider);
    final todayActiveEventsAsync = ref.watch(todayActiveEventsProvider);
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final reservesNowBarSpace = todayActiveEventsAsync.when(
      data: (events) => events.isNotEmpty,
      loading: () => true,
      error: (_, _) => true,
    );
    final bottomContentPadding = reservesNowBarSpace
        ? EventNowBar.height + bottomSafeArea + MinglitSpacing.medium
        : MinglitSpacing.xlarge;

    // Auto-fetch next page when first page is completely filtered out
    // by client-side eligibility/nearby filter (events empty but hasMore=true).
    ref.listen(recommendationFeedProvider, (_, next) {
      next.whenData((s) {
        if (s.events.isEmpty && s.hasMore && !s.isLoadingMore) {
          unawaited(ref.read(recommendationFeedProvider.notifier).loadMore());
        }
      });
    });

    return Scaffold(
      // Fix #667: keep the persistent now bar above the system inset.
      bottomSheet: const SafeArea(top: false, child: EventNowBar()),
      // Fix #192: Pull-to-refresh to reload the explore feed from scratch.
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(recommendationFeedProvider.notifier).refresh(),
        child: CustomScrollView(
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
              // Fix #141: Equalize action button spacing and padding alignment
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
                  // Fix #141: Use IconButton for consistent touch target (48x48)
                  // and ripple effect with other app bar actions
                  IconButton(
                    onPressed: () => const MyPageRoute().push<void>(context),
                    icon: CircleAvatar(
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
                    // Fix #102: use go (not push) so GoRouter redirect
                    // fires after login
                    // Fix #634: auth_coordinator 직접 참조 → home_coordinator.goToLogin 전환
                    onPressed: () => homeCoordinator.goToLogin(from: '/'),
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
            recommendationState.when(
              data: (state) {
                if (state.events.isEmpty && !state.hasMore) {
                  return const SliverFillRemaining(
                    child: Center(child: Text('추천 이벤트가 없습니다')),
                  );
                }
                // First page fully filtered client-side: show loading while
                // auto-fetch (triggered by ref.listen above) loads next page.
                if (state.events.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(child: MinglitCircularProgressIndicator()),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.only(
                    top: MinglitSpacing.small,
                    bottom: MinglitSpacing.medium,
                  ),
                  sliver: SliverList.separated(
                    itemCount: state.events.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: MinglitSpacing.small),
                    itemBuilder: (context, index) {
                      final event = state.events[index];
                      return MinglitEventCard(
                        event: event,
                        // Fix #634: event_coordinator 직접 참조 → home_coordinator 전환
                        onTap: () => homeCoordinator.pushEventDetail(event.id),
                      );
                    },
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(child: MinglitCircularProgressIndicator()),
              ),
              // Fix #192: 피드 로드 실패 시 에러 메시지와 재시도 버튼 표시
              error: (_, _) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('피드를 불러오지 못했습니다'),
                      const SizedBox(height: MinglitSpacing.small),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(recommendationFeedProvider),
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (recommendationState.value?.isLoadingMore ?? false)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MinglitSpacing.medium,
                    bottom: MinglitSpacing.medium,
                  ),
                  child: Center(child: MinglitCircularProgressIndicator()),
                ),
              ),
            SliverPadding(
              // Fix #667: reserve scroll space so the last card is not hidden
              // behind the fixed EventNowBar.
              padding: EdgeInsets.only(bottom: bottomContentPadding),
            ),
          ],
        ),
      ),
    );
  }
}
