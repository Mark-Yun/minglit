import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/src/data/models/event.dart';
import 'package:minglit_kit/src/theme/minglit_theme.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_chip.dart';
import 'package:minglit_kit/src/ui/widgets/common/minglit_image.dart';

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
  });

  /// Event data to render.
  final Event event;

  /// Optional tap handler for the card.
  final VoidCallback? onTap;

  /// Fixed width of the card.
  final double width;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final party = event.party;
    final location = event.location ?? party?.location;

    // Calculate D-Day
    final now = DateTime.now();
    final difference = event.startTime.difference(now).inDays;
    final dDayLabel = difference == 0
        ? '오늘'
        : difference > 0
        ? 'D-$difference'
        : '종료';

    // Format Date
    final dateLabel = DateFormat(
      'M월 d일 (E) HH:mm',
      'ko_KR',
    ).format(event.startTime);

    // Get Lowest Price
    final lowestPrice = event.tickets?.fold<int?>(
      null,
      (min, t) => min == null || t.price < min ? t.price : min,
    );
    final priceLabel = lowestPrice != null
        ? '${NumberFormat('#,###').format(lowestPrice)}원~'
        : '가격 미정';

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
            // Event Image with D-Day Badge
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: MinglitImage(
                    path: party?.imageUrl ?? '',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: MinglitSpacing.small,
                  left: MinglitSpacing.small,
                  child: MinglitChip(
                    label: dDayLabel,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(MinglitSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partner Info
                  if (partner != null) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: partner.profileImageUrl != null
                              ? NetworkImage(partner.profileImageUrl!)
                              : null,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          child: partner.profileImageUrl == null
                              ? Icon(
                                  Icons.store,
                                  size: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                )
                              : null,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            partner.name,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: MinglitSpacing.small),
                  ],

                  // Title
                  Text(
                    party?.title ?? event.title ?? '제목 없음',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MinglitSpacing.small),

                  // Location & Date Row
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
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
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.small),

                  // Price
                  Text(
                    priceLabel,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
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
