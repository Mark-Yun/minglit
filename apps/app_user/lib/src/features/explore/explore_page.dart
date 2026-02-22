import 'package:app_user/src/features/explore/logic/explore_coordinator.dart';
import 'package:app_user/src/features/explore/providers/explore_state_provider.dart';
import 'package:app_user/src/features/explore/widgets/applied_filters_row.dart';
import 'package:app_user/src/features/explore/widgets/explore_search_bar.dart';
import 'package:app_user/src/features/explore/widgets/filter_chip_bar.dart';
import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class ExplorePage extends ConsumerWidget {
  const ExplorePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('탐색'),
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(text: '추천'),
              Tab(text: '검색'),
            ],
          ),
        ),
        body: const Column(
          children: [
            SizedBox(height: MinglitSpacing.small),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: ExploreSearchBar(),
            ),
            SizedBox(height: MinglitSpacing.small),
            Expanded(
              child: TabBarView(
                children: [
                  _RecommendationTab(),
                  _SearchResultsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationTab extends ConsumerWidget {
  const _RecommendationTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationAsync = ref.watch(recommendationEventsProvider);
    final coordinator = ref.read(exploreCoordinatorProvider);

    return Column(
      children: [
        const ExploreFilterChipBar(),
        const AppliedFiltersRow(),
        Expanded(
          child: recommendationAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const Center(child: Text('추천 이벤트가 없습니다'));
              }
              return ListView.separated(
                padding: const EdgeInsets.all(MinglitSpacing.medium),
                itemCount: events.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: MinglitSpacing.small),
                itemBuilder: (context, index) {
                  final event = events[index];
                  return MinglitEventCard(
                    event: event,
                    onTap: () => coordinator.pushEventDetail(event.id),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsTab extends ConsumerWidget {
  const _SearchResultsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final searchAsync = ref.watch(searchResultsProvider);
    final coordinator = ref.read(exploreCoordinatorProvider);

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Text(
              '검색어를 입력하세요',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return searchAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return Center(
            child: Text(
              '"$query" 검색 결과가 없습니다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          itemCount: events.length,
          separatorBuilder: (_, _) =>
              const SizedBox(height: MinglitSpacing.small),
          itemBuilder: (context, index) {
            final event = events[index];
            return MinglitEventCard(
              event: event,
              onTap: () => coordinator.pushEventDetail(event.id),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => const Center(
        child: Text('검색 중 오류가 발생했습니다'),
      ),
    );
  }
}
