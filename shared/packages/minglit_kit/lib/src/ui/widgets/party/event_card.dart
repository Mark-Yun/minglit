import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/data/models/partner.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';
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
    this.width = 240,
  }) : _isLoading = false;

  /// Named constructor for loading skeleton state.
  const MinglitEventCard.loading({
    super.key,
    this.event,
    this.onTap,
    this.width = 240,
  }) : _isLoading = true;

  /// Event data to render.
  final Event? event;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  /// Fixed width of the card.
  final double width;

  /// Internal flag for loading state.
  final bool _isLoading;

  @override
  Widget build(BuildContext context) {
    if (_isLoading || event == null) {
      return _EventCardSkeleton(width: width);
    }

    final theme = Theme.of(context);
    final party = event!.party;
    final location = event!.location ?? party?.location;

    // Calculate D-Day
    final now = DateTime.now();
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
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          boxShadow: [
            BoxShadow(
              color: MinglitColors.textPrimary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
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
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                        ],
                        stops: const [0.45, 1.0],
                      ),
                    ),
                  ),
                ),
                // D-Day chip (top-left)
                Positioned(
                  top: MinglitSpacing.small,
                  left: MinglitSpacing.small,
                  child: MinglitChip(
                    label: dDayLabel,
                    color: theme.colorScheme.primary,
                  ),
                ),
                // Participant overlay (top-right)
                Positioned(
                  top: MinglitSpacing.small,
                  right: MinglitSpacing.small,
                  child: _ParticipantOverlay(
                    current: event!.currentParticipants,
                    max: event!.maxParticipants,
                  ),
                ),
                // Partner overlay (bottom-left) - only if partner exists
                if (partner != null)
                  Positioned(
                    bottom: MinglitSpacing.small,
                    left: MinglitSpacing.small,
                    child: _PartnerOverlay(partner: partner),
                  ),
              ],
            ),

            // Content area
            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
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
                  const SizedBox(height: MinglitSpacing.xsmall),

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

/// Participant count overlay with battery-style indicator.
///
/// Displays a 3-segment battery gauge based on participation ratio:
/// - 0–33%: 1 filled segment (orange)
/// - 34–66%: 2 filled segments (mint)
/// - 67–100%: 3 filled segments (purple)
class _ParticipantOverlay extends StatelessWidget {
  const _ParticipantOverlay({required this.current, required this.max});

  final int current;
  final int max;

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
      0 => Colors.white.withValues(alpha: 0.3),
      1 => MinglitColors.secondary,
      2 => MinglitColors.tertiary,
      _ => MinglitColors.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 3-segment battery gauge
          for (var i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            Container(
              width: 10,
              height: 8,
              decoration: BoxDecoration(
                color: i < filledCount
                    ? segmentColor
                    : Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
          const SizedBox(width: 6),
          Text(
            '$current/$max',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 2),
          const Icon(Icons.people_outline, size: 11, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: partner.profileImageUrl != null
                ? NetworkImage(partner.profileImageUrl!)
                : null,
            backgroundColor: Colors.white24,
            child: partner.profileImageUrl == null
                ? const Icon(Icons.store, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 90),
            child: Text(
              partner.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
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
  const _EventCardSkeleton({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        boxShadow: [
          BoxShadow(
            color: MinglitColors.textPrimary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 9,
            child: MinglitSkeleton(borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MinglitSkeleton(width: width * 0.8, height: 16),
                const SizedBox(height: MinglitSpacing.xsmall),
                Row(
                  children: [
                    MinglitSkeleton(width: width * 0.5, height: 12),
                    const Spacer(),
                    MinglitSkeleton(width: width * 0.2, height: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
