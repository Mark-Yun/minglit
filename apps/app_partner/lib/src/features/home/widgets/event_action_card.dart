import 'package:app_partner/src/features/home/home_event_phase.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:minglit_kit/minglit_kit.dart';

export 'package:app_partner/src/features/home/widgets/event_action_card_empty.dart';

part '_event_action_card_stats.dart';

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

    // Phase-specific styling — use theme-aware colors for dark mode support
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
        // Fix #957: highlight (0.1) preserves original event phase
        // background intensity
        MinglitColors.success.withValues(alpha: MinglitOpacity.highlight),
        colorScheme.outlineVariant,
        colorScheme.surfaceContainerLowest,
        '신청 현황 보기',
        Icons.assignment_outlined,
        '이벤트 수정',
        Icons.edit_outlined,
        '공유/홍보',
        Icons.share_outlined,
      ),
      EventPhase.preparing => (
        _preparingLabel(event),
        colorScheme.error,
        colorScheme.error.withValues(alpha: MinglitOpacity.highlight),
        colorScheme.outlineVariant,
        colorScheme.surfaceContainerLowest,
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
        colorScheme.primary.withValues(alpha: MinglitOpacity.highlight),
        colorScheme.primary,
        colorScheme.surfaceContainerLowest,
        '체크인 계속하기',
        Icons.qr_code_scanner,
        '참석 현황',
        Icons.people_outlined,
        null,
        null,
      ),
      EventPhase.ended => (
        _endedLabel(event),
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
        colorScheme.outlineVariant,
        colorScheme.surfaceContainerLow,
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
                // Fix #596: displayLarge+fontSize:28 → headlineMedium (28px)
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: phase == EventPhase.ended
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
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
                      backgroundColor: colorScheme.outlineVariant,
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

