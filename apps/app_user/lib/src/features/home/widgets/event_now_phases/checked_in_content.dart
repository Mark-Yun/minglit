import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

// ---------------------------------------------------------------------------
// Phase 2: Checked In — confirmation + participant count + avatars
// ---------------------------------------------------------------------------

class CheckedInContent extends StatelessWidget {
  const CheckedInContent({required this.activeEvent, super.key});

  final TodayActiveEvent activeEvent;

  @override
  Widget build(BuildContext context) {
    final event = activeEvent.event;
    final theme = Theme.of(context);
    final participantCount = event.currentParticipants;
    final maxParticipants = event.maxParticipants;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MinglitSpacing.screenEdge,
        vertical: MinglitSpacing.large,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: MinglitColors.textSecondary.withValues(
                alpha: MinglitOpacity.muted,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Check icon
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: MinglitColors.success,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: MinglitColors.background,
              size: 36,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // Confirmation text
          Text(
            '체크인 완료!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: MinglitSpacing.small),

          Text(
            event.title ?? '이벤트',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: MinglitColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: MinglitSpacing.xlarge),

          // Participant count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.people_outline,
                color: MinglitColors.textSecondary,
                size: MinglitIconSize.small,
              ),
              const SizedBox(width: MinglitSpacing.small),
              Text(
                '참석자 $participantCount / $maxParticipants명',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: MinglitColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: MinglitSpacing.medium),

          // Participant avatars placeholder row
          _ParticipantAvatarRow(count: participantCount),

          const SizedBox(height: MinglitSpacing.xlarge),

          // Waiting message
          Text(
            '곧 매칭이 시작될 거예요',
            style: theme.textTheme.bodySmall?.copyWith(
              color: MinglitColors.textSecondary,
            ),
          ),
          const SizedBox(height: MinglitSpacing.medium),
        ],
      ),
    );
  }
}

/// Avatar row showing participant circles (max 5 + remaining count).
class _ParticipantAvatarRow extends StatelessWidget {
  const _ParticipantAvatarRow({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final displayCount = count.clamp(0, 5);
    final remaining = count - displayCount;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < displayCount; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: MinglitColors.primary.withValues(
                alpha: MinglitOpacity.highlight + (i * 0.15),
              ),
              child: Icon(
                Icons.person,
                size: 16,
                color: MinglitColors.primary.withValues(
                  alpha: MinglitOpacity.separator,
                ),
              ),
            ),
          ),
        if (remaining > 0)
          Padding(
            padding: const EdgeInsets.only(left: MinglitSpacing.small),
            child: Text(
              '+$remaining',
              style: theme.textTheme.bodySmall?.copyWith(
                color: MinglitColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
