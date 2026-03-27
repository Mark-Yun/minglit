import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/theme/minglit_text_theme_extension.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_skeleton.dart';

/// **Minglit Event Card**
///
/// A reusable card widget to display event information.
class MinglitEventCard extends StatelessWidget {
  /// Creates an event card for the given [event].
  const MinglitEventCard({
    required this.event,
    super.key,
    this.onTap,
    @visibleForTesting this.currentTime,
  }) : _isLoading = false;

  /// Named constructor for loading skeleton state.
  const MinglitEventCard.loading({
    super.key,
    this.event,
    this.onTap,
    this.currentTime,
  }) : _isLoading = true;

  /// Event data to render.
  final Event? event;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

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

    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image with overlays
            Stack(
              children: [
                // Image
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MinglitImage(
                    path: party?.imageUrl ?? '',
                    fit: BoxFit.cover,
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
                // Partner overlay (top-left) - only if partner exists
                if (partner != null)
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
                    party?.title ?? event!.title ?? '제목 없음',
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
                          '${location?.name ?? "장소 미정"} · $dateLabel',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  });

  final int current;
  final int max;
  final String dDayLabel;

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
          const Icon(
            Icons.person,
            size: 13,
            color: MinglitColors.background,
          ),
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
          Text(dDayLabel, style: overlayStyle),
        ],
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

/// Skeleton loader for event card.
class _EventCardSkeleton extends StatelessWidget {
  const _EventCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: MinglitSkeleton(borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
              vertical: MinglitSpacing.small,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MinglitSkeleton(width: w * 0.8, height: 16),
                    const SizedBox(height: MinglitSpacing.xsmall),
                    Row(
                      children: [
                        MinglitSkeleton(width: w * 0.5, height: 12),
                        const Spacer(),
                        MinglitSkeleton(width: w * 0.2, height: 12),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
