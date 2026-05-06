import 'package:flutter/material.dart';
import 'package:minglit_kit/minglit_kit.dart';

class HomeUpcomingEventCard extends StatelessWidget {
  const HomeUpcomingEventCard({
    required this.event,
    required this.onTap,
    super.key,
  });

  final Event event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: MinglitSpacing.medium,
          vertical: MinglitSpacing.xsmall,
        ),
        leading: const Icon(Icons.event_outlined),
        title: Text(
          event.title ?? '이벤트 준비 중',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          '준비 중',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
