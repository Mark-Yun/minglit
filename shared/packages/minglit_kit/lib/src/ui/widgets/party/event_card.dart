import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// **Minglit Event Card**
///
/// A reusable card widget to display event information.
class MinglitEventCard extends StatelessWidget {
  const MinglitEventCard({
    required this.event,
    super.key,
    this.onTap,
    this.width = 240,
  });

  final Event event;
  final VoidCallback? onTap;
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                  // Location & Date
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
                          location?.name ?? '장소 미정',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
                  Text(
                    party?.title ?? event.title ?? '제목 없음',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: MinglitSpacing.small),

                  // Date & Price
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: MinglitSpacing.xsmall),
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
