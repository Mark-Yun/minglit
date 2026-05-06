import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mds/src/theme/minglit_text_theme_extension.dart';
import 'package:mds/src/theme/minglit_theme.dart';
import 'package:mds/src/ui/widgets/common/minglit_image.dart';
import 'package:mds/src/ui/widgets/common/minglit_skeleton.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/data/models/tag.dart';

part '_event_card_overlays.dart';
part '_event_card_skeleton.dart';
part '_event_card_tags.dart';

/// Internal enum representing the visual state of the event card.
///
/// Priority (highest first): ended > soldOut > today > normal
enum _EventCardState {
  /// Default — event is in the future and has available capacity.
  normal,

  /// Event starts today (difference == 0).
  today,

  /// Event is at or over max capacity (currentParticipants >= maxParticipants).
  soldOut,

  /// Event start time is in the past (difference < 0).
  ended,
}

/// **Minglit Event Card**
///
/// A reusable card widget to display event information.
class MinglitEventCard extends StatelessWidget {
  /// Creates an event card for the given [event].
  const MinglitEventCard({
    required this.event,
    super.key,
    this.onTap,
    this.showPartnerOverlay = true,
    @visibleForTesting this.currentTime,
  }) : _isLoading = false;

  /// Named constructor for loading skeleton state.
  const MinglitEventCard.loading({
    super.key,
    this.event,
    this.onTap,
    this.showPartnerOverlay = true,
    this.currentTime,
  }) : _isLoading = true;

  /// Event data to render.
  final Event? event;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  /// Whether to show the partner badge overlay on the image.
  final bool showPartnerOverlay;

  /// Override current time for D-day calculation (testing only).
  final DateTime? currentTime;

  /// Internal flag for loading state.
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isLoading || event == null) {
      return const _EventCardSkeleton();
    }

    final theme = Theme.of(context);
    final party = event!.party;
    final location = event!.location ?? party?.location;

    // Calculate D-Day
    final now = currentTime ?? DateTime.now();
    final difference = event!.startTime.difference(now).inDays;
    final dDayLabel = difference == 0
        ? '오늘'
        : difference > 0
        ? 'D-$difference'
        : '종료';

    // Fix #478: Determine card visual state
    // Priority: ended > soldOut > today > normal
    final cardState = difference < 0
        ? _EventCardState.ended
        : event!.currentParticipants >= event!.maxParticipants
        ? _EventCardState.soldOut
        : difference == 0
        ? _EventCardState.today
        : _EventCardState.normal;

    // Format Date
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event!.startTime);

    // Get Lowest Price
    final lowestPrice = event!.tickets?.fold<int?>(
      null,
      (min, t) => min == null || t.price < min ? t.price : min,
    );
    final priceLabel = lowestPrice == null
        ? '가격 미정'
        : lowestPrice == 0
        ? '무료'
        : '${NumberFormat('#,###').format(lowestPrice)}원~';

    final partner = party?.partner;

    final title = party?.title ?? event!.title ?? '제목 없음';
    final locationName = location?.name ?? '장소 미정';

    // Fix #996: 카드 전체를 하나의 시맨틱 노드로 병합하여 정보 전달
    // Fix #1558: sold-out/ended 상태를 label에 포함 — 스크린 리더가 상태를 인식할 수 있도록.
    // soldOut은 "만석, 참여 불가"(스크린리더) + "마감"(시각 배지)로 용어를 분리 —
    // 원래 #996 sold-out badge Semantics의 "이벤트 만석, 참여 불가" announce를 유지한다.
    final stateLabel = switch (cardState) {
      _EventCardState.soldOut => ', 만석, 참여 불가',
      _EventCardState.ended => ', 종료된 이벤트',
      _ => '',
    };
    return Semantics(
      container: true,
      label:
          '이벤트: $title, $dateLabel, $locationName, $priceLabel, '
          '$dDayLabel, 참가자 ${event!.currentParticipants}/${event!.maxParticipants}명'
          '$stateLabel',
      button: onTap != null,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        // Fix #1558: 부모 Semantics가 onTap을 직접 노출하므로 자식의 자동 시맨틱 탭 액션을 제거해
        // 트리에 중복 액션이 등록되지 않도록 한다.
        excludeFromSemantics: true,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: cardState == _EventCardState.today
                ? Border.all(color: MinglitColors.secondary, width: 2)
                : null,
          ),
          child: ColoredBox(
            color: theme.colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image with overlays
                Stack(
                  children: [
                    // Fix #478: grayscale ColorFiltered for ended state
                    // Fix #1382: 2:1 비율로 변경 — 브라우징 효율 개선 (PM 채택)
                    AspectRatio(
                      aspectRatio: 2 / 1,
                      child: ColorFiltered(
                        colorFilter: cardState == _EventCardState.ended
                            ? const ColorFilter.mode(
                                Colors
                                    .grey, // ignore: minglit_no_hardcoded_colors -- saturation ColorFilter requires neutral grey for desaturation effect
                                BlendMode.saturation,
                              )
                            : const ColorFilter.mode(
                                MinglitColors.transparent,
                                BlendMode.dst,
                              ),
                        child: MinglitImage(
                          // Fix #1540: event.imageUrl uses effectiveImageUrls
                          // which falls back to party.imageUrls — avoids broken
                          // image when event has its own image or party is null
                          path: event!.imageUrl ?? '',
                          fit: BoxFit.cover,
                          excludeFromSemantics: true,
                        ),
                      ),
                    ),
                    // Gradient fade at bottom
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              MinglitColors.transparent,
                              MinglitColors.textPrimary.withValues(
                                alpha: MinglitOpacity.gradient,
                              ),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ),
                    // Fix #478: soldOut scrim + "마감" badge overlay
                    if (cardState == _EventCardState.soldOut)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            // ignore: minglit_no_hardcoded_colors -- pure black scrim; no equivalent MDS token
                            color: Colors.black.withValues(
                              alpha: MinglitOpacity.strong,
                            ),
                          ),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: MinglitSpacing.medium,
                                vertical: MinglitSpacing.small,
                              ),
                              decoration: BoxDecoration(
                                // ignore: minglit_no_hardcoded_colors -- pure black badge bg; no equivalent MDS token
                                color: Colors.black.withValues(
                                  alpha: MinglitOpacity.separator,
                                ),
                                borderRadius: BorderRadius.circular(
                                  MinglitRadius.small,
                                ),
                              ),
                              child: Text(
                                '마감',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: MinglitColors.background,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Fix #1214: 파트너 상세 컨텍스트에서는 중복 파트너 뱃지를 숨긴다.
                    if (showPartnerOverlay && partner != null)
                      Positioned(
                        top: MinglitSpacing.small,
                        left: MinglitSpacing.small,
                        child: _PartnerOverlay(partner: partner),
                      ),
                    // D-Day + Participant overlay (top-right)
                    Positioned(
                      top: MinglitSpacing.small,
                      right: MinglitSpacing.small,
                      child: _ParticipantDDayOverlay(
                        current: event!.currentParticipants,
                        max: event!.maxParticipants,
                        dDayLabel: dDayLabel,
                        cardState: cardState,
                      ),
                    ),
                  ],
                ),

                // Content area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.medium,
                    vertical: MinglitSpacing.small,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: MinglitSpacing.xxsmall),

                      // Location & Date Row
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              '$locationName · $dateLabel',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            priceLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      // Tag chips — prefer party-level tags, fall back to
                      // event-level tags (Tag Discovery #1094-1096).
                      // Displays at most 3 tags + "+N" overflow badge.
                      if (party?.tags ?? event!.tags case final tags?
                          when tags.isNotEmpty) ...[
                        const SizedBox(height: MinglitSpacing.xsmall),
                        _TagChipRow(tags: tags),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

