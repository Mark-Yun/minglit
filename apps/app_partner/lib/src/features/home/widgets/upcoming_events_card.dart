import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Shows upcoming events (next 7 days) as horizontal scrolling cards.
class UpcomingEventsCard extends StatelessWidget {
  const UpcomingEventsCard({
    required this.events,
    required this.onEventTap,
    // Fix #422: 이벤트 요약 자세히 버튼 콜백
    this.onViewAllTap,
    super.key,
  });

  final List<Event> events;
  final void Function(Event event) onEventTap;
  final VoidCallback? onViewAllTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Fix #422: 헤더에 가로 패딩 적용 (수평 스크롤은 화면 전체 사용)
        Padding(
          padding: const EdgeInsets.only(
            left: MinglitSpacing.medium,
            right: MinglitSpacing.medium,
            bottom: MinglitSpacing.small,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                '다가오는 이벤트',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Fix #422: 이벤트 요약 자세히 버튼 추가
              if (onViewAllTap != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: onViewAllTap,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '자세히',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.medium,
            ),
            child: SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  '예정된 이벤트가 없습니다',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              // Fix #422: 좌우 패딩으로 카드 잘림 방지
              padding: const EdgeInsets.symmetric(
                horizontal: MinglitSpacing.medium,
              ),
              itemCount: events.take(5).length,
              separatorBuilder: (_, _) => const SizedBox(
                width: MinglitSpacing.small,
              ),
              itemBuilder: (context, index) {
                final event = events[index];
                return _EventCard(
                  event: event,
                  onTap: () => onEventTap(event),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFormat = DateFormat('M/d (E)', 'ko_KR');

    return SizedBox(
      width: 160,
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MinglitRadius.card),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MinglitRadius.card),
          child: Padding(
            padding: const EdgeInsets.all(MinglitSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  event.title ?? '이벤트',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateFormat.format(event.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    // Fix #185: 파티명 표시
                    if (event.party?.title != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        event.party!.title,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
