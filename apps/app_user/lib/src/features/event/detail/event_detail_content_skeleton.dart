part of 'event_detail_page.dart';

class _SkeletonTabBarDelegate extends SliverPersistentHeaderDelegate {
  const _SkeletonTabBarDelegate();

  @override
  double get minExtent => kTextTabBarHeight + 1;

  @override
  double get maxExtent => kTextTabBarHeight + 1;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.scaffoldBackgroundColor,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: kTextTabBarHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
                vertical: MinglitSpacing.small,
              ),
              child: Row(
                children: [
                  MinglitSkeleton(width: 60, height: 20),
                  SizedBox(width: MinglitSpacing.medium),
                  MinglitSkeleton(width: 60, height: 20),
                  SizedBox(width: MinglitSpacing.medium),
                  MinglitSkeleton(width: 60, height: 20),
                ],
              ),
            ),
          ),
          Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SkeletonTabBarDelegate oldDelegate) => false;
}

class _EventDetailContentSkeleton extends StatelessWidget {
  const _EventDetailContentSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final imageHeight = screenWidth * 9 / 16;
    final expandedHeight = imageHeight;

    return CustomScrollView(
      slivers: [
        // 1. Hero Image Header
        SliverAppBar(
          expandedHeight: expandedHeight,
          pinned: true,
          leading: const BackButton(),
          backgroundColor: theme.scaffoldBackgroundColor,
          flexibleSpace: FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                MinglitSkeleton(width: double.infinity, height: expandedHeight),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topPadding + kToolbarHeight + 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          MinglitColors.textPrimary.withValues(alpha: 0.26),
                          MinglitColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        // Tab Bar Skeleton
        const SliverPersistentHeader(
          pinned: true,
          delegate: _SkeletonTabBarDelegate(),
        ),
        // 2. Main Info
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Partner Row
                Row(
                  children: [
                    const MinglitSkeleton(
                      width: MinglitRadius.input * 2,
                      height: MinglitRadius.input * 2,
                      borderRadius: BorderRadius.all(
                        Radius.circular(MinglitRadius.input),
                      ),
                    ),
                    const SizedBox(width: MinglitSpacing.small),
                    const MinglitSkeleton(width: 100, height: 14),
                    const SizedBox(width: MinglitSpacing.xsmall),
                    Icon(
                      Icons.chevron_right,
                      size: MinglitIconSize.small,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: MinglitSpacing.small),

                // Title
                const MinglitSkeleton(width: double.infinity, height: 28),
                const SizedBox(height: MinglitSpacing.xsmall),
                const MinglitSkeleton(width: 200, height: 28),
                const SizedBox(height: MinglitSpacing.medium),

                // Info Cards
                const Row(
                  children: [
                    MinglitSkeleton(width: 24, height: 24),
                    SizedBox(width: MinglitSpacing.small),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MinglitSkeleton(width: 120, height: 16),
                        SizedBox(height: MinglitSpacing.xsmall),
                        MinglitSkeleton(width: 80, height: 14),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: MinglitSpacing.small),
                const Row(
                  children: [
                    MinglitSkeleton(width: 24, height: 24),
                    SizedBox(width: MinglitSpacing.small),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MinglitSkeleton(width: 140, height: 16),
                        SizedBox(height: MinglitSpacing.xsmall),
                        MinglitSkeleton(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),

                const Divider(height: MinglitSpacing.xlarge),

                // 3. Description (Rich Text)
                const MinglitSkeleton(width: 80, height: 24),
                const SizedBox(height: MinglitSpacing.medium),
                const MinglitSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: MinglitSpacing.xsmall),
                const MinglitSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: MinglitSpacing.xsmall),
                const MinglitSkeleton(width: double.infinity, height: 16),
                const SizedBox(height: MinglitSpacing.xsmall),
                MinglitSkeleton(width: screenWidth * 0.6, height: 16),

                const SizedBox(height: MinglitSpacing.xlarge),

                // 4. Entry Conditions
                const MinglitSkeleton(width: 100, height: 24),
                const SizedBox(height: MinglitSpacing.medium),
                const MinglitSkeleton(width: double.infinity, height: 80),
                const SizedBox(height: MinglitSpacing.small),
                const MinglitSkeleton(width: double.infinity, height: 80),

                const SizedBox(
                  height: MinglitSpacing.xlarge * 4,
                ), // Bottom padding for FAB
              ],
            ),
          ),
        ),
      ],
    );
  }
}
