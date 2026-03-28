import 'package:flutter/material.dart';

/// A row of summary chips showing pending approvals, upcoming events,
/// and preparing events.
class TodoSummaryChips extends StatelessWidget {
  const TodoSummaryChips({
    required this.pendingCount,
    required this.upcomingCount,
    required this.preparingCount,
    required this.onPendingTap,
    super.key,
  });

  final int pendingCount;
  final int upcomingCount;
  final int preparingCount;
  final VoidCallback onPendingTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TodoChip(
          label: '승인 대기',
          count: pendingCount,
          onTap: onPendingTap,
        ),
        const SizedBox(width: 8),
        _TodoChip(
          label: '다가오는 이벤트',
          count: upcomingCount,
          onTap: null,
        ),
        const SizedBox(width: 8),
        _TodoChip(
          label: '준비 중',
          count: preparingCount,
          onTap: (context) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('준비 중인 이벤트 목록')),
            );
          },
        ),
      ],
    );
  }
}

class _TodoChip extends StatelessWidget {
  const _TodoChip({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final int count;

  /// When null, chip is non-interactive (for 다가오는 이벤트).
  /// When a BuildContext callback, uses context to show SnackBar.
  final dynamic onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isActive = count > 0;

    final chipColor =
        isActive ? colorScheme.primaryContainer : colorScheme.surfaceContainer;
    final labelColor = isActive
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    VoidCallback? tapCallback;
    if (onTap is VoidCallback) {
      tapCallback = onTap as VoidCallback;
    } else if (onTap is Function(BuildContext)) {
      tapCallback = () => (onTap as Function(BuildContext))(context);
    }

    return GestureDetector(
      onTap: tapCallback,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(color: labelColor),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
