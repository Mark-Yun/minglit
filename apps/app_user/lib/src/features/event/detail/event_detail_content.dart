part of 'event_detail_page.dart';

class _EventDetailContent extends ConsumerStatefulWidget {
  const _EventDetailContent({required this.event});

  final Event event;

  @override
  ConsumerState<_EventDetailContent> createState() =>
      _EventDetailContentState();
}

class _EventDetailContentState extends ConsumerState<_EventDetailContent>
    with TickerProviderStateMixin {
  final _scrollController = ScrollController();
  bool _showTitle = false;
  bool _bannerDismissed = false;
  late TabController _tabController;
  final GlobalKey _section1Key = GlobalKey();
  final GlobalKey _section2Key = GlobalKey();
  final GlobalKey _section3Key = GlobalKey();
  final GlobalKey _section4Key = GlobalKey();
  final GlobalKey _section5Key = GlobalKey();
  bool _isTabTapScroll = false;

  double _collapseThreshold = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final collapsed = _scrollController.offset > _collapseThreshold;
    if (collapsed != _showTitle) {
      setState(() => _showTitle = collapsed);
    }

    if (_isTabTapScroll) return;

    // Update active tab based on section scroll positions
    final keys = [
      _section1Key,
      _section2Key,
      _section3Key,
      _section4Key,
      _section5Key,
    ];
    var activeIndex = 0;
    for (var i = 0; i < keys.length; i++) {
      final context = keys[i].currentContext;
      if (context == null) continue;
      final renderObject = context.findRenderObject();
      if (renderObject == null || !renderObject.attached) continue;
      final viewport = RenderAbstractViewport.maybeOf(renderObject);
      if (viewport == null) continue;
      final revealOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
      // Account for pinned headers (SliverAppBar collapsed + TabBar)
      const pinnedHeight = kToolbarHeight + kTextTabBarHeight + 1;
      if (_scrollController.offset >= revealOffset - pinnedHeight) {
        activeIndex = i;
      }
    }
    if (_tabController.index != activeIndex) {
      _tabController.animateTo(activeIndex);
    }
  }

  void _scrollToSection(GlobalKey key) {
    final context = key.currentContext;
    if (context == null) return;
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) return;
    final viewport = RenderAbstractViewport.maybeOf(renderObject);
    if (viewport == null) return;

    const pinnedHeight = kToolbarHeight + kTextTabBarHeight + 1;
    final revealOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
    final targetOffset = (revealOffset - pinnedHeight).clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    _isTabTapScroll = true;
    unawaited(
      _scrollController
          .animateTo(
            targetOffset,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          )
          .then((_) => _isTabTapScroll = false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final imageHeight = screenWidth * 9 / 16;
    // primary: true adds topPadding automatically — don't double-add it.
    final expandedHeight = imageHeight;
    _collapseThreshold = imageHeight - kToolbarHeight;

    final event = widget.event;
    final party = event.party;
    final partner = party?.partner;
    final location = event.location ?? party?.location;
    final partnerProfileImageUrl = partner?.profileImageUrl;
    final eventTitle = party?.title ?? event.title ?? '제목 없음';
    final user = ref.watch(currentUserProvider);
    final iconColor = _showTitle ? theme.colorScheme.onSurface : Colors.white;

    // Date Format
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event.startTime);

    final durationHours = event.endTime.difference(event.startTime).inHours;

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () async {
            return ref.refresh(eventDetailControllerProvider(event.id).future);
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Hero Image Header
              SliverAppBar(
                expandedHeight: expandedHeight,
                pinned: true,
                title: _showTitle
                    ? Text(
                        eventTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
                centerTitle: false,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      MinglitImageCarousel(
                        imageUrls: party?.imageUrls ?? [],
                        height: imageHeight + topPadding,
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: topPadding + kToolbarHeight + 16,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.black45, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: BackButton(color: iconColor),
                actions: [
                  IconButton(
                    onPressed: () {
                      unawaited(
                        ShareUtils.shareEvent(
                          eventTitle: eventTitle,
                          eventId: event.id,
                          baseUrl: ref.watch(minglitDomainsProvider).userApp,
                        ),
                      );
                    },
                    icon: Icon(Icons.share_outlined, color: iconColor),
                    tooltip: '공유하기',
                  ),
                  if (user != null)
                    Padding(
                      padding: const EdgeInsets.only(
                        right: MinglitSpacing.small,
                      ),
                      child: MinglitSocialButton(
                        targetId: event.partyId, // Like the party
                        targetType: SocialTargetType.party,
                        interactionType: SocialInteractionType.like,
                        activeColor: iconColor,
                        inactiveColor: iconColor,
                        tooltip: '좋아요',
                      ),
                    ),
                ],
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
              ),

              // Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverTabBarDelegate(
                  tabController: _tabController,
                  onTabTap: (index) {
                    final keys = [
                      _section1Key,
                      _section2Key,
                      _section3Key,
                      _section4Key,
                      _section5Key,
                    ];
                    _scrollToSection(keys[index]);
                  },
                ),
              ),

              // Section 1: 기본 정보
              SliverToBoxAdapter(
                key: _section1Key,
                child: Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Partner Row
                      if (partner != null) ...[
                        GestureDetector(
                          onTap: () => ref
                              .read(eventCoordinatorProvider)
                              .pushPartnerDetail(partner.id),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: MinglitRadius.input, // 12
                                backgroundImage: partnerProfileImageUrl != null
                                    ? NetworkImage(partnerProfileImageUrl)
                                    : null,
                                child: partnerProfileImageUrl == null
                                    ? const Icon(
                                        Icons.store,
                                        size: MinglitIconSize.xsmall,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: MinglitSpacing.small),
                              Flexible(
                                child: Text(
                                  partner.name,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(width: MinglitSpacing.xsmall),
                              Icon(
                                Icons.chevron_right,
                                size: MinglitIconSize.small,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: MinglitSpacing.small),
                      ],
                      // Title
                      Text(
                        eventTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                      // Info Cards
                      _InfoTile(
                        icon: Icons.calendar_today_outlined,
                        title: dateLabel,
                        subtitle: '$durationHours시간 진행',
                      ),
                      const SizedBox(height: MinglitSpacing.small),
                      _InfoTile(
                        icon: Icons.location_on_outlined,
                        title: location?.name ?? '장소 미정',
                        subtitle: location?.address ?? '주소 정보 없음',
                      ),
                      const Divider(height: MinglitSpacing.xlarge),
                      // Entry Conditions (without verification badges)
                      _EntryConditionsSection(event: event),
                    ],
                  ),
                ),
              ),

              // Section 2: 상세 소개
              SliverToBoxAdapter(
                key: _section2Key,
                child: Padding(
                  padding: const EdgeInsets.all(MinglitSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _QuillViewer(description: party?.description ?? {}),
                    ],
                  ),
                ),
              ),

              // Section 3: 참가 현황
              SliverToBoxAdapter(
                key: _section3Key,
                child: _ParticipationSection(event: event),
              ),

              // Section 4: 필요 인증
              SliverToBoxAdapter(
                key: _section4Key,
                child: _VerificationSection(event: event),
              ),

              // Section 5: 환불 정책
              SliverToBoxAdapter(
                key: _section5Key,
                child: const _RefundPolicySection(),
              ),

              // Bottom padding for last section scrollability
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height / 2,
                ),
              ),
            ],
          ),
        ),
        if (!_bannerDismissed)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: OpenInAppBanner(
              onDismiss: () => setState(() => _bannerDismissed = true),
            ),
          ),
      ],
    );
  }
}

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
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black26, Colors.transparent],
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
