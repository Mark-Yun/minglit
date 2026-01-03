import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

class PartyEventListItem extends StatelessWidget {
  const PartyEventListItem({
    required this.event,
    this.onTap,
    super.key,
  });

  final Event event;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeStr = DateFormat('yyyy.MM.dd (E) HH:mm', 'ko_KR').format(
      event.startTime,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: MinglitSpacing.small),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MinglitRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(MinglitSpacing.medium),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(MinglitSpacing.small),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: colorScheme.onSurfaceVariant,
                  size: MinglitIconSize.small,
                ),
              ),
              const SizedBox(width: MinglitSpacing.medium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? '기본 회차',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: MinglitSpacing.xxsmall),
                    Text(
                      timeStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${event.currentParticipants}/${event.maxParticipants}명',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    '신청중',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: MinglitSpacing.small),
              Icon(
                Icons.chevron_right,
                color: colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
