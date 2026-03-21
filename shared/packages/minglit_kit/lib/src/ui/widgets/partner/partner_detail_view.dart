import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/social_interaction.dart';
import 'package:minglit_kit/src/features/social/ui/minglit_social_button.dart';
import 'package:minglit_kit/src/logic/providers/event_feed_provider.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_async_value_widget.dart';
import 'package:minglit_kit/src/ui/widgets/party/event_card.dart';

/// A detailed view of a Partner profile.
///
/// Fix #171: 알림받기 텍스트 버튼, 진행중인 이벤트 가로 카드, 더 보기 버튼
class PartnerDetailView extends ConsumerWidget {
  /// Creates a [PartnerDetailView].
  const PartnerDetailView({
    required this.partner,
    this.onEventTap,
    this.onMoreEventsTap,
    super.key,
  });

  /// The partner data to display.
  final Partner partner;

  /// Callback when an event card is tapped.
  final void Function(Event event)? onEventTap;

  /// Callback when the "더 보기" button is tapped.
  final VoidCallback? onMoreEventsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              if (partner.profileImageUrl != null)
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button, // 40
                  backgroundImage: NetworkImage(partner.profileImageUrl!),
                )
              else
                CircleAvatar(
                  radius: MinglitRadius.card + MinglitRadius.button, // 40
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  child: Icon(
                    Icons.store,
                    size: MinglitIconSize.xlarge * 1.25,
                    color: theme.colorScheme.outline,
                  ),
                ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      partner.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (partner.address != null)
                      Text(
                        partner.address!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: MinglitSpacing.small),
                    // Fix #171: 알림받기 아이콘에 텍스트 추가
                    MinglitSocialButton(
                      targetId: partner.id,
                      targetType: SocialTargetType.partner,
                      interactionType: SocialInteractionType.subscribe,
                      label: '알림받기',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Introduction
          _buildSection(context, '소개', partner.introduction ?? '소개글이 없습니다.'),
          const Divider(height: MinglitSpacing.xlarge * 1.5),

          // Fix #171: 진행중인 이벤트 (가로 카드형 + 더 보기)
          _buildEventSection(ref, context),
          const Divider(height: MinglitSpacing.xlarge * 1.5),

          // Business Info
          _buildSection(context, '사업자 정보', ''),
          _buildInfoRow(context, '상호명', partner.bizName),
          _buildInfoRow(context, '대표자', partner.representativeName),
          _buildInfoRow(context, '사업자번호', partner.bizNumber),
          const SizedBox(height: MinglitSpacing.large),

          // Contact Info
          _buildSection(context, '연락처', ''),
          _buildInfoRow(context, '이메일', partner.contactEmail),
          _buildInfoRow(context, '전화번호', partner.contactPhone),
        ],
      ),
    );
  }

  Widget _buildEventSection(WidgetRef ref, BuildContext context) {
    final theme = Theme.of(context);
    final eventsAsync = ref.watch(
      partnerEventsProvider(partnerId: partner.id),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix #171: 헤더에 더 보기 버튼 추가
        Row(
          children: [
            Text(
              '진행중인 이벤트',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (onMoreEventsTap != null)
              TextButton(
                onPressed: onMoreEventsTap,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '더 보기',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: MinglitSpacing.medium),
        MinglitAsyncValueWidget(
          value: eventsAsync,
          data: (events) {
            if (events.isEmpty) {
              return Text(
                '등록된 이벤트가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              );
            }
            // Fix #171: 가로 카드형 썸네일, 1.5개 보이도록
            return _buildHorizontalEventList(context, events);
          },
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }

  Widget _buildHorizontalEventList(
    BuildContext context,
    List<Event> events,
  ) {
    // Card width = ~2/3 of available width so ~1.5 cards show
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = (screenWidth - MinglitSpacing.large * 2) * 0.65;

    return SizedBox(
      height: cardWidth * (9 / 16) + 56, // image height + content area
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        separatorBuilder: (_, _) =>
            const SizedBox(width: MinglitSpacing.small),
        itemBuilder: (context, index) {
          final event = events[index];
          return SizedBox(
            width: cardWidth,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MinglitRadius.card),
              child: MinglitEventCard(
                event: event,
                onTap: onEventTap != null ? () => onEventTap!(event) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: MinglitSpacing.small),
          Text(
            content,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: MinglitSpacing.xxsmall),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
