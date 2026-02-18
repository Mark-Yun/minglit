part of 'event_detail_page.dart';

class _EventDetailContent extends ConsumerWidget {
  const _EventDetailContent({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final party = event.party;
    final partner = party?.partner;
    final location = event.location ?? party?.location;
    final partnerProfileImageUrl = partner?.profileImageUrl;
    final eventTitle = party?.title ?? event.title ?? '제목 없음';

    // Date Format
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event.startTime);

    return RefreshIndicator(
      onRefresh: () async {
        return ref.refresh(eventDetailControllerProvider(event.id).future);
      },
      child: CustomScrollView(
        slivers: [
          // 1. Hero Image Header
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: MinglitImageCarousel(
                imageUrls: party?.imageUrls ?? [],
              ),
            ),
            leading: BackButton(color: theme.colorScheme.onPrimary),
            actions: [
              IconButton(
                onPressed: () {
                  unawaited(
                    ShareUtils.shareEvent(
                      eventTitle: eventTitle,
                      eventId: event.id,
                    ),
                  );
                },
                icon: Icon(
                  Icons.share_outlined,
                  color: theme.colorScheme.onPrimary,
                ),
                tooltip: '공유하기',
              ),
              Padding(
                padding: const EdgeInsets.only(right: MinglitSpacing.small),
                child: MinglitSocialButton(
                  targetId: event.partyId, // Like the party
                  targetType: SocialTargetType.party,
                  interactionType: SocialInteractionType.like,
                  activeColor: theme.colorScheme.onPrimary,
                  inactiveColor: theme.colorScheme.onPrimary.withValues(
                    alpha: 0.7,
                  ),
                ),
              ),
            ],
            backgroundColor: theme.colorScheme.primary,
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
                    Row(
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
                        Text(
                          partner.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
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
                    subtitle:
                        '${event.endTime.difference(event.startTime).inHours}'
                        '시간 진행',
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
    );
  }
}
