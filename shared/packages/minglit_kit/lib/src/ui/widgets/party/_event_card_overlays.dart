part of 'event_card.dart';

/// Participant count overlay with battery-style indicator and D-day label.
///
/// Displays a 3-segment battery gauge based on participation ratio:
/// - 0–33%: 1 filled segment (orange)
/// - 34–66%: 2 filled segments (mint)
/// - 67–100%: 3 filled segments (purple)
///
/// Also displays the D-day label (e.g., "오늘", "D-5", "종료").
class _ParticipantDDayOverlay extends StatelessWidget {
  const _ParticipantDDayOverlay({
    required this.current,
    required this.max,
    required this.dDayLabel,
    required this.cardState,
  });

  final int current;
  final int max;
  final String dDayLabel;

  // Fix #478: cardState used to color D-Day label and overlay background
  final _EventCardState cardState;

  @override
  Widget build(BuildContext context) {
    final ratio = max > 0 ? (current / max).clamp(0.0, 1.0) : 0.0;
    final filledCount = ratio <= 0
        ? 0
        : ratio <= 0.33
        ? 1
        : ratio <= 0.66
        ? 2
        : 3;
    final segmentColor = switch (filledCount) {
      0 => MinglitColors.background.withValues(alpha: MinglitOpacity.muted),
      1 => MinglitColors.secondary,
      2 => MinglitColors.tertiary,
      _ => MinglitColors.primary,
    };

    // Fix #474: fontSize 13 → ThemeExtension chipLabel
    final ext = Theme.of(context).extension<MinglitTextThemeExtension>()!;
    final overlayStyle = ext.chipLabel.copyWith(
      color: MinglitColors.background,
      fontWeight: FontWeight.w400,
    );

    // Fix #478: ended state uses muted grey overlay background
    final overlayBgColor = cardState == _EventCardState.ended
        // ignore: minglit_no_hardcoded_colors -- greyed-out scrim; no equivalent MDS token
        ? Colors.grey.withValues(
            alpha: MinglitOpacity.scrimDark,
          )
        : MinglitColors.textPrimary.withValues(alpha: MinglitOpacity.overlay);

    // Fix #478: D-Day label color — amber for today
    final dDayStyle = cardState == _EventCardState.today
        ? overlayStyle.copyWith(
            color: MinglitColors.secondary,
            fontWeight: FontWeight.w600,
          )
        : overlayStyle;

    // Fix #996: Semantics 래퍼로 스크린 리더 접근성 지원
    return Semantics(
      label: ratio >= 1.0 ? '이벤트 만석, 참여 불가' : '참가자 $current/$max명, $dDayLabel',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.small,
          vertical: MinglitSpacing.xsmall,
        ),
        decoration: BoxDecoration(
          color: overlayBgColor,
          borderRadius: BorderRadius.circular(MinglitRadius.small),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person, size: 13, color: MinglitColors.background),
            const SizedBox(width: 3),
            // 3-segment battery gauge
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: MinglitSpacing.xxsmall),
              Container(
                width: 10,
                height: 8,
                decoration: BoxDecoration(
                  color: i < filledCount
                      ? segmentColor
                      : MinglitColors.background.withValues(
                          alpha: MinglitOpacity.subtle,
                        ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
            const SizedBox(width: MinglitSpacing.xsmall2),
            Text('$current/$max', style: overlayStyle),
            // Fix #996: ratio >= 1.0일 때 만석 텍스트 표시
            if (ratio >= 1.0) ...[
              const SizedBox(width: MinglitSpacing.xsmall),
              Text(
                '만석',
                style: overlayStyle.copyWith(
                  color: MinglitColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(width: MinglitSpacing.xsmall),
            Text(
              '·',
              style: overlayStyle.copyWith(
                color: MinglitColors.background.withValues(
                  alpha: MinglitOpacity.separator,
                ),
              ),
            ),
            const SizedBox(width: MinglitSpacing.xsmall),
            const Icon(
              Icons.calendar_today,
              size: 13,
              color: MinglitColors.background,
            ),
            const SizedBox(width: 3),
            Text(dDayLabel, style: dDayStyle),
          ],
        ),
      ),
    );
  }
}

/// Partner info overlay with avatar and name.
class _PartnerOverlay extends StatelessWidget {
  const _PartnerOverlay({required this.partner});

  final Partner partner;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.small,
        vertical: MinglitSpacing.xsmall,
      ),
      decoration: BoxDecoration(
        color: MinglitColors.textPrimary.withValues(
          alpha: MinglitOpacity.overlay,
        ),
        borderRadius: BorderRadius.circular(MinglitRadius.small),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: partner.profileImageUrl != null
                ? NetworkImage(partner.profileImageUrl!)
                : null,
            backgroundColor: MinglitColors.background.withValues(
              alpha: MinglitOpacity.placeholder,
            ),
            child: partner.profileImageUrl == null
                ? const Icon(
                    Icons.store,
                    size: 12,
                    color: MinglitColors.background,
                  )
                : null,
          ),
          const SizedBox(width: MinglitSpacing.xsmall2),
          // Fix #474: fontSize 13 → ThemeExtension chipLabel
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              partner.name,
              style: Theme.of(context)
                  .extension<MinglitTextThemeExtension>()!
                  .chipLabel
                  .copyWith(
                    color: MinglitColors.background,
                    fontWeight: FontWeight.w400,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
