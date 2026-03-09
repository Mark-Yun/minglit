part of 'event_detail_page.dart';

class _EventDetailContent extends ConsumerStatefulWidget {
  const _EventDetailContent({required this.event});

  final Event event;

  @override
  ConsumerState<_EventDetailContent> createState() =>
      _EventDetailContentState();
}

class _EventDetailContentState extends ConsumerState<_EventDetailContent> {
  final _scrollController = ScrollController();
  bool _showTitle = false;
  bool _bannerDismissed = false;

  double _collapseThreshold = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final imageHeight = screenWidth * 9 / 16;
    final expandedHeight = imageHeight + topPadding;
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
                        height: expandedHeight,
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
                              colors: [
                                Colors.black45,
                                Colors.transparent,
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
                    icon: Icon(
                      Icons.share_outlined,
                      color: iconColor,
                    ),
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
                backgroundColor: theme.scaffoldBackgroundColor,
              ),

              // 2. Main Info
              SliverToBoxAdapter(
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

                      // 3. Description (Rich Text)
                      Text(
                        '상세 소개',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: MinglitSpacing.medium),
                      _QuillViewer(description: party?.description ?? {}),

                      const SizedBox(height: MinglitSpacing.xlarge),

                      // 4. Entry Conditions
                      _EntryConditionsSection(event: event),

                      const SizedBox(
                        height: MinglitSpacing.xlarge * 4,
                      ), // Bottom padding for FAB
                    ],
                  ),
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

class _EventDetailContentSkeleton extends StatelessWidget {
  const _EventDetailContentSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final topPadding = MediaQuery.paddingOf(context).top;
    final imageHeight = screenWidth * 9 / 16;
    final expandedHeight = imageHeight + topPadding;

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
                MinglitSkeleton(
                  width: double.infinity,
                  height: expandedHeight,
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
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
