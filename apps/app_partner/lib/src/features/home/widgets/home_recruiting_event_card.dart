import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeRecruitingEventCard extends StatelessWidget {
  const HomeRecruitingEventCard({
    required this.event,
    required this.pendingCount,
    required this.onTap,
    super.key,
  });

  final Event event;
  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: pendingCount > 0
          ? MinglitColors.error
          : theme.colorScheme.onSurfaceVariant,
      fontWeight: pendingCount > 0 ? FontWeight.w700 : FontWeight.w500,
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        leading: const Icon(Icons.groups_outlined),
        title: Text(
          event.title ?? '모집 중인 이벤트',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          pendingCount > 0 ? '모집 중 · 심사 대기 $pendingCount건' : '모집 중',
          style: subtitleStyle,
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
