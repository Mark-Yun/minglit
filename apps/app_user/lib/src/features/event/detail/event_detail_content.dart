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
      // getOffsetToReveal already accounts for pinned slivers via
      // maxScrollObstructionExtentBefore — compare directly.
      final revealed = viewport.getOffsetToReveal(
        renderObject,
        0,
        rect: Rect.fromLTWH(0, 0, renderObject.paintBounds.width, 0),
      );
      if (_scrollController.offset >= revealed.offset) {
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

    // getOffsetToReveal already accounts for pinned slivers via
    // maxScrollObstructionExtentBefore — do NOT subtract pinnedHeight.
    // Use rect to target only the top edge of the section.
    final revealed = viewport.getOffsetToReveal(
      renderObject,
      0,
      rect: Rect.fromLTWH(0, 0, renderObject.paintBounds.width, 0),
    );
    final targetOffset = revealed.offset.clamp(
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
    final iconColor = _showTitle
        ? theme.colorScheme.onSurface
        : MinglitColors.background;

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
                    // Fix #140: onPrimary resolves to black in dark mode — use onSurface to match icon color
                    ? Text(
                        eventTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
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
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                MinglitColors.textPrimary.withValues(
                                  alpha: 0.45,
                                ),
                                MinglitColors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                leading: BackButton(color: iconColor),
                actions: [
                  if (partner != null && user != null)
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: iconColor),
                      onSelected: (value) async {
                        switch (value) {
                          case 'block':
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('차단하기'),
                                content: const Text(
                                  '이 파트너를 차단하시겠습니까?\n'
                                  '이 파트너의 이벤트가 더 이상 표시되지 않습니다.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('차단'),
                                  ),
                                ],
                              ),
                            );
                            if ((confirmed ?? false) && context.mounted) {
                              await ref
                                  .read(socialRepositoryProvider)
                                  .blockPartner(partner.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('파트너가 차단되었습니다'),
                                  ),
                                );
                              }
                            }
                          case 'report':
                            if (context.mounted) {
                              await showReportBottomSheet(
                                context,
                                ref,
                                partner.id,
                              );
                            }
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'block',
                          child: ListTile(
                            leading: Icon(Icons.block),
                            title: Text('차단하기'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'report',
                          child: ListTile(
                            leading: Icon(Icons.flag),
                            title: Text('신고하기'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                ],
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: MinglitColors.background,
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
                child: Padding(
                  key: _section1Key,
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
                      const SizedBox(height: MinglitSpacing.medium),
                      Wrap(
                        spacing: MinglitSpacing.small,
                        runSpacing: MinglitSpacing.small,
                        children: [
                          // Fix #136: Remove dislike button, change like active color to brand primary
                          MinglitSocialActionChip(
                            targetId: event.partyId,
                            targetType: SocialTargetType.party,
                            interactionType: SocialInteractionType.like,
                            label: '좋아요',
                            activeIcon: Icons.thumb_up,
                            inactiveIcon: Icons.thumb_up_outlined,
                            activeColor: MinglitColors.primary,
                            // Fix #634: auth_coordinator 직접 참조 → event_coordinator.pushLogin 전환
                            onUnauthenticatedTap: user == null
                                ? () => ref
                                      .read(eventCoordinatorProvider)
                                      .pushLogin()
                                : null,
                          ),
                          // Fix #136: Use large size to match social action chip updates
                          MinglitChip(
                            label: '공유하기',
                            icon: Icons.share_outlined,
                            size: MinglitChipSize.large,
                            onTap: () => unawaited(
                              ShareUtils.shareEvent(
                                eventTitle: eventTitle,
                                eventId: event.id,
                                baseUrl: ref
                                    .watch(minglitDomainsProvider)
                                    .userApp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Fix #137: 참여현황 위젯을 참가 현황 탭으로 이동
                    ],
                  ),
                ),
              ),

              // Section 2: 상세 소개
              SliverToBoxAdapter(
                child: Padding(
                  key: _section2Key,
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
              // Fix #137: 상세정보에서 참가 현황 탭으로 _EntryConditionsSection 이동
              SliverToBoxAdapter(
                child: SizedBox(
                  key: _section3Key,
                  child: _EntryConditionsSection(event: event),
                ),
              ),

              // Section 4: 필요 인증
              SliverToBoxAdapter(
                child: SizedBox(
                  key: _section4Key,
                  child: _VerificationSection(event: event),
                ),
              ),

              // Section 5: 환불 정책
              SliverToBoxAdapter(
                child: SizedBox(
                  key: _section5Key,
                  child: _RefundPolicySection(event: event),
                ),
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
