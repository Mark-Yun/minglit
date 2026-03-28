import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

/// Three summary chips showing pending actions at a glance.
class TodoSummaryChips extends StatelessWidget {
  const TodoSummaryChips({
    required this.pendingApplications,
    required this.upcomingEvents,
    required this.onPendingTap,
    required this.onUpcomingTap,
    super.key,
  });

  final int pendingApplications;
  final int upcomingEvents;
  final VoidCallback onPendingTap;
  final VoidCallback onUpcomingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TodoChip(
            count: pendingApplications,
            label: '승인 대기',
            activeColor: MinglitColors.error,
            activeBackground: const Color(0xFFFFF0F0),
            onTap: onPendingTap,
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: _TodoChip(
            count: upcomingEvents,
            label: '다가오는 이벤트',
            activeColor: Theme.of(context).colorScheme.primary,
            activeBackground: const Color(0xFFF0F0FF),
            onTap: onUpcomingTap,
          ),
        ),
        const SizedBox(width: MinglitSpacing.small),
        Expanded(
          child: _TodoChip(
            count: 0,
            label: '미답변 리뷰',
            activeColor: MinglitColors.warning,
            activeBackground: const Color(0xFFFFF8E1),
            comingSoon: true,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('리뷰 기능은 곧 출시됩니다'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TodoChip extends StatelessWidget {
  const _TodoChip({
    required this.count,
    required this.label,
    required this.activeColor,
    required this.activeBackground,
    required this.onTap,
    this.comingSoon = false,
  });

  final int count;
  final String label;
  final Color activeColor;
  final Color activeBackground;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final isActive = count > 0 && !comingSoon;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.sm,
          vertical: MinglitSpacing.medium,
        ),
        decoration: BoxDecoration(
          color: isActive ? activeBackground : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(MinglitRadius.input),
        ),
        child: Column(
          children: [
            if (comingSoon)
              Text(
                '-',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFAAAAAA),
                ),
              )
            else
              Text(
                count.toString(),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isActive ? activeColor : const Color(0xFFAAAAAA),
                ),
              ),
            const SizedBox(height: MinglitSpacing.xxsmall),
            Text(
              comingSoon ? '준비 중' : label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isActive ? activeColor : const Color(0xFFAAAAAA),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
