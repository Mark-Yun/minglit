part of 'event_detail_page.dart';

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate({required this.tabController, required this.onTabTap});

  final TabController tabController;
  final void Function(int) onTabTap;

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
      child: Column(
        children: [
          TabBar(
            controller: tabController,
            isScrollable: true,
            // Fix #77: remove default 52dp left padding from scrollable TabBar
            tabAlignment: TabAlignment.start,
            onTap: onTabTap,
            tabs: const [
              Tab(text: '기본 정보'),
              Tab(text: '상세 소개'),
              Tab(text: '참가 현황'),
              Tab(text: '필요 인증'),
              Tab(text: '환불 정책'),
            ],
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) => false;
}
