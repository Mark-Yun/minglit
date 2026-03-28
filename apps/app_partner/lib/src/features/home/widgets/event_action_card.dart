import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Displays the current active event with phase-specific badge and CTA.
class EventActionCard extends StatelessWidget {
  const EventActionCard({
    required this.event,
    required this.onMainAction,
    super.key,
  });

  final Event event;
  final VoidCallback onMainAction;

  String get _phase => (event.metadata['phase'] as String?) ?? 'recruiting';

  String get _badgeText {
    switch (_phase) {
      case 'recruiting':
        return '모집 중';
      case 'preparing':
        return '준비 중';
      case 'live':
        return 'LIVE';
      case 'ended':
        return '종료';
      default:
        return '모집 중';
    }
  }

  String get _ctaText {
    switch (_phase) {
      case 'recruiting':
        return '신청 현황 보기';
      case 'preparing':
        return '체크인 준비';
      case 'live':
        return '체크인 계속하기';
      case 'ended':
        return '다음 회차 만들기';
      default:
        return '신청 현황 보기';
    }
  }

  Color _badgeColor(ColorScheme colorScheme) {
    switch (_phase) {
      case 'recruiting':
        return colorScheme.primary;
      case 'preparing':
        return colorScheme.secondary;
      case 'live':
        return Colors.red;
      case 'ended':
        return colorScheme.outline;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillRatio = event.maxParticipants > 0
        ? event.currentParticipants / event.maxParticipants
        : 0.0;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: MinglitSpacing.small,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _badgeColor(colorScheme),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _badgeText,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: Text(
                    event.title ?? '이벤트',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: MinglitSpacing.medium),
            Row(
              children: [
                Text(
                  '${event.currentParticipants} / ${event.maxParticipants}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: fillRatio.clamp(0.0, 1.0),
              backgroundColor: colorScheme.outlineVariant,
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onMainAction,
                child: Text(_ctaText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state card shown when there is no active event.
class EventActionCardEmpty extends StatelessWidget {
  const EventActionCardEmpty({
    required this.hasParties,
    required this.onCreateEvent,
    required this.onCreateParty,
    super.key,
  });

  final bool hasParties;
  final VoidCallback onCreateEvent;
  final VoidCallback onCreateParty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MinglitRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(MinglitSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '진행 중인 이벤트가 없습니다',
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: MinglitSpacing.medium),
            SizedBox(
              width: double.infinity,
              child: hasParties
                  ? FilledButton(
                      onPressed: onCreateEvent,
                      child: const Text('이벤트 만들기'),
                    )
                  : FilledButton(
                      onPressed: onCreateParty,
                      child: const Text('파티 만들기'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
