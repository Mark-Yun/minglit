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
        body: Column(
          children: [
            const SizedBox(height: MinglitSpacing.small),
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              child: ExploreSearchBar(),
            ),
            const SizedBox(height: MinglitSpacing.small),
            const ExploreFilterChipBar(),
            const AppliedFiltersRow(),
            const Expanded(
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
    final aiRecs = ref.watch(aiRecommendationsProvider);
    final coordinator = ref.read(exploreCoordinatorProvider);

    return CustomScrollView(
      slivers: [
        aiRecs.when(
          data: (events) {
            if (events.isEmpty) {
              return const SliverToBoxAdapter(child: SizedBox.shrink());
            }
            return SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(MinglitSpacing.medium),
                    child: Row(
                      children: [
                        const Text('✨'),
                        const SizedBox(width: 4),
                        Text(
                          'AI 추천',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: MinglitSpacing.medium,
                      ),
                      itemCount: events.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: MinglitSpacing.small),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _AiRecommendationCard(
                          event: event,
                          onTap: () => coordinator.pushEventDetail(event.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: MinglitSpacing.medium),
                ],
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(MinglitSpacing.large),
                child: CircularProgressIndicator(),
              ),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: SizedBox.shrink(),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: Text(
              '큐레이션',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SliverPadding(
          padding: EdgeInsets.all(MinglitSpacing.medium),
          sliver: _CurationGrid(),
        ),
      ],
    );
  }
}

class _CurationGrid extends ConsumerWidget {
  const _CurationGrid();

  static const _curationTypes = [
    EventFeedType.nearest,
    EventFeedType.newArrivals,
    EventFeedType.closingSoon,
    EventFeedType.earlyBird,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coordinator = ref.read(exploreCoordinatorProvider);

    return SliverList.separated(
      itemCount: _curationTypes.length,
      separatorBuilder: (_, __) => const SizedBox(height: MinglitSpacing.small),
      itemBuilder: (context, index) {
        final type = _curationTypes[index];
        return Card(
          child: ListTile(
            leading: Icon(_iconFor(type), color: MinglitColors.primary),
            title: Text(type.title),
            subtitle: Text(type.sortLabel),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => coordinator.pushEventCuration(type),
          ),
        );
      },
    );
  }

  IconData _iconFor(EventFeedType type) {
    return switch (type) {
      EventFeedType.nearest => Icons.near_me,
      EventFeedType.newArrivals => Icons.fiber_new,
      EventFeedType.closingSoon => Icons.timer,
      EventFeedType.earlyBird => Icons.local_offer,
      EventFeedType.aiRecommended => Icons.auto_awesome,
    };
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
          separatorBuilder: (_, __) =>
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
      error: (e, _) => Center(
        child: Text('검색 중 오류가 발생했습니다'),
      ),
    );
  }
}

class _AiRecommendationCard extends StatelessWidget {
  const _AiRecommendationCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = event.effectiveImageUrls.isNotEmpty
        ? event.effectiveImageUrls.first
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              if (imageUrl != null)
                Image.network(
                  imageUrl,
                  width: 280,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 280,
                    height: 220,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.image, size: 48),
                  ),
                )
              else
                Container(
                  width: 280,
                  height: 220,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image, size: 48),
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        event.title ?? event.party?.title ?? '',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.party?.location != null)
                        Text(
                          event.party!.location!.name,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MinglitColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '✨ AI 추천',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
