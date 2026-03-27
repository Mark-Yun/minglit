import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Phase of the nearest event, determines UI and available actions.
enum EventPhase {
  recruiting, // > 3 hours until start
  preparing, // <= 3 hours until start
  live, // started, not ended
  ended, // ended within 24 hours
}

/// Determines the phase of an event based on current time.
EventPhase getEventPhase(Event event) {
  final now = DateTime.now();
  final start = event.startTime;
  final end = event.endTime;

  if (now.isAfter(end)) return EventPhase.ended;
  if (now.isAfter(start)) return EventPhase.live;
  if (start.difference(now).inHours < 3) return EventPhase.preparing;
  return EventPhase.recruiting;
}

/// Selects the most relevant event to display in the action card.
/// Priority: live > preparing > ended (within 24h) > recruiting (soonest).
Event? selectPrimaryEvent(List<Event> events) {
  if (events.isEmpty) return null;

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(hours: 24));

  Event? bestLive;
  Event? bestPreparing;
  Event? bestEnded;
  Event? bestRecruiting;

  for (final e in events) {
    final phase = getEventPhase(e);
    switch (phase) {
      case EventPhase.live:
        if (bestLive == null || e.startTime.isBefore(bestLive.startTime)) {
          bestLive = e;
        }
      case EventPhase.preparing:
        if (bestPreparing == null ||
            e.startTime.isBefore(bestPreparing.startTime)) {
          bestPreparing = e;
        }
      case EventPhase.ended:
        if (e.endTime.isAfter(cutoff)) {
          if (bestEnded == null || e.endTime.isAfter(bestEnded.endTime)) {
            bestEnded = e;
          }
        }
      case EventPhase.recruiting:
        if (bestRecruiting == null ||
            e.startTime.isBefore(bestRecruiting.startTime)) {
          bestRecruiting = e;
        }
    }
  }

  return bestLive ?? bestPreparing ?? bestEnded ?? bestRecruiting;
}

/// The main event action card on the home dashboard.
/// Shows the nearest event with phase-appropriate actions.
class EventActionCard extends StatelessWidget {
  const EventActionCard({
    required this.event,
    required this.onMainAction,
    required this.onSecondaryAction1,
    required this.onSecondaryAction2,
    super.key,
  });

  final Event event;
  final VoidCallback onMainAction;
  final VoidCallback onSecondaryAction1;
  final VoidCallback? onSecondaryAction2;

  @override
  Widget build(BuildContext context) {
    final phase = getEventPhase(event);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeFmt = DateFormat('HH:mm');

    // Phase-specific styling
    final (
      phaseLabel,
      phaseColor,
      phaseBg,
      borderColor,
      cardBg,
      mainLabel,
      mainIcon,
      sec1Label,
      sec1Icon,
      sec2Label,
      sec2Icon,
    ) = switch (phase) {
      EventPhase.recruiting => (
        _recruitingLabel(event),
        MinglitColors.success,
        const Color(0xFFE8F5E9),
        const Color(0xFFE8E0FF),
        const Color(0xFFFAFAFE),
        '신청 현황 보기',
        Icons.assignment_outlined,
        '이벤트 수정',
        Icons.edit_outlined,
        '공유/홍보',
        Icons.share_outlined,
      ),
      EventPhase.preparing => (
        _preparingLabel(event),
        const Color(0xFFE65100),
        const Color(0xFFFFF3E0),
        const Color(0xFFE8E0FF),
        const Color(0xFFFAFAFE),
        '체크인 준비',
        Icons.qr_code_scanner,
        '참석자 명단',
        Icons.people_outlined,
        '안내 발송',
        Icons.message_outlined,
      ),
      EventPhase.live => (
        _liveLabel(event),
        colorScheme.primary,
        colorScheme.primary.withValues(alpha: 0.1),
        colorScheme.primary,
        const Color(0xFFF5F0FF),
        '체크인 계속하기',
        Icons.qr_code_scanner,
        '참석 현황',
        Icons.people_outlined,
        null,
        null,
      ),
      EventPhase.ended => (
        _endedLabel(event),
        const Color(0xFF888888),
        const Color(0xFFF5F5F5),
        const Color(0xFFE0E0E0),
        const Color(0xFFFAFAFA),
        '다음 회차 만들기',
        Icons.replay,
        '상세 결과',
        Icons.bar_chart_outlined,
        null,
        null,
      ),
    };

    final capacity = event.maxParticipants;
    final current = event.currentParticipants;
    final ratio = capacity > 0 ? current / capacity : 0.0;

    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.medium),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(MinglitRadius.button),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MinglitSpacing.small,
              vertical: MinglitSpacing.xsmall,
            ),
            decoration: BoxDecoration(
              color: phaseBg,
              borderRadius: BorderRadius.circular(MinglitRadius.small),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: phaseColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: MinglitSpacing.xsmall2),
                Text(
                  phaseLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: phaseColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),

          // Time + event info
          Row(
            children: [
              Text(
                timeFmt.format(event.startTime),
                style: theme.textTheme.displayLarge?.copyWith(
                  color: phase == EventPhase.ended
                      ? const Color(0xFF888888)
                      : colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: MinglitSpacing.small),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title ?? '',
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      event.party?.title ?? '',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Capacity bar (hide for ended)
          if (phase != EventPhase.ended) ...[
            const SizedBox(height: MinglitSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFE8E0FF),
                      valueColor: AlwaysStoppedAnimation(
                        phase == EventPhase.live
                            ? MinglitColors.success
                            : colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: MinglitSpacing.sm),
                Text(
                  phase == EventPhase.live
                      ? '체크인 $current/$capacity명'
                      : '$current/$capacity명',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: phase == EventPhase.live
                        ? MinglitColors.success
                        : colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],

          // Ended stats row
          if (phase == EventPhase.ended) ...[
            const SizedBox(height: MinglitSpacing.sm),
            _EndedStatsRow(event: event),
          ],

          const SizedBox(height: MinglitSpacing.sm),

          // Main CTA (full width)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onMainAction,
              icon: Icon(mainIcon, size: MinglitIconSize.small),
              label: Text(mainLabel),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MinglitRadius.input),
                ),
                backgroundColor: phase == EventPhase.live
                    ? MinglitColors.success
                    : null,
              ),
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),

          // Secondary actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondaryAction1,
                  icon: Icon(sec1Icon, size: MinglitIconSize.small),
                  label: Text(
                    sec1Label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: MinglitSpacing.small,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(MinglitRadius.input),
                    ),
                  ),
                ),
              ),
              if (sec2Label != null && sec2Icon != null) ...[
                const SizedBox(width: MinglitSpacing.small),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onSecondaryAction2,
                    icon: Icon(sec2Icon, size: MinglitIconSize.small),
                    label: Text(
                      sec2Label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: MinglitSpacing.small,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          MinglitRadius.input,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _recruitingLabel(Event event) {
    final days = event.startTime.difference(DateTime.now()).inDays;
    if (days == 0) return '모집 중 · 오늘';
    if (days == 1) return '모집 중 · 내일';
    return '모집 중 · D-$days';
  }

  static String _preparingLabel(Event event) {
    final diff = event.startTime.difference(DateTime.now());
    final hours = diff.inHours;
    final mins = diff.inMinutes % 60;
    if (hours > 0) return '준비 중 · $hours시간 $mins분 후';
    return '준비 중 · $mins분 후';
  }

  static String _liveLabel(Event event) {
    final mins = DateTime.now().difference(event.startTime).inMinutes;
    return 'LIVE · $mins분 경과';
  }

  static String _endedLabel(Event event) {
    final hours = DateTime.now().difference(event.endTime).inHours;
    if (hours < 1) return '종료 · 방금 전';
    return '종료 · $hours시간 전';
  }
}

class _EndedStatsRow extends StatelessWidget {
  const _EndedStatsRow({required this.event});
  final Event event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final capacity = event.maxParticipants;
    final current = event.currentParticipants;
    final fmt = NumberFormat('#,###');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MinglitRadius.input),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Row(
        children: [
          _StatCell(label: '참석 확정', value: '$current명', theme: theme),
          _StatCell(label: '매출', value: '₩${fmt.format(0)}', theme: theme),
          _StatCell(
            label: '출석률',
            value: capacity > 0
                ? '${(current / capacity * 100).round()}%'
                : '-',
            theme: theme,
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.theme,
  });
  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: MinglitSpacing.small,
          horizontal: MinglitSpacing.xsmall,
        ),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: theme.textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

/// Empty state when no events exist.
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
    return Container(
      padding: const EdgeInsets.all(MinglitSpacing.large),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(MinglitRadius.button),
        border: Border.all(color: const Color(0xFFF0F0F0)),
      ),
      child: Column(
        children: [
          Icon(
            hasParties ? Icons.event_outlined : Icons.celebration_outlined,
            size: MinglitIconSize.xlarge * 1.5,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: MinglitSpacing.sm),
          Text(
            hasParties ? '이벤트를 만들어 신청을 받아보세요' : '첫 파티를 만들어보세요',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(height: MinglitSpacing.medium),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: hasParties ? onCreateEvent : onCreateParty,
              icon: const Icon(Icons.add, size: MinglitIconSize.small),
              label: Text(hasParties ? '이벤트 만들기' : '파티 만들기'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  vertical: MinglitSpacing.sm,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MinglitRadius.input),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
